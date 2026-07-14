import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auth.dart';
import 'credentials.dart';
import 'tdlib_ffi.dart';
import 'tg_client.dart';

class TdError implements Exception {
  final int code;
  final String message;

  const TdError(this.code, this.message);

  @override
  String toString() => message;
}

AuthStep? mapAuthorizationState(String type) {
  switch (type) {
    case 'authorizationStateWaitPhoneNumber':
      return AuthStep.waitPhone;
    case 'authorizationStateWaitCode':
      return AuthStep.waitCode;
    case 'authorizationStateWaitPassword':
      return AuthStep.waitPassword;
    case 'authorizationStateReady':
      return AuthStep.ready;
    case 'authorizationStateLoggingOut':
      return AuthStep.loggingOut;
    default:
      return null;
  }
}

Exception tdErrorToException(Map<String, dynamic> err) {
  final code = (err['code'] as num?)?.toInt() ?? 0;
  final message = err['message'] as String? ?? 'Unknown Telegram error';
  if (code == 429) {
    final m = RegExp(r'retry after (\d+)').firstMatch(message);
    if (m != null) return FloodWaitException(int.parse(m.group(1)!));
  }
  return TdError(code, message);
}

void _receiveLoop(SendPort port) {
  final td = TdLib.tryLoad();
  if (td == null) return;
  while (true) {
    final raw = td.receiveRaw(1.0);
    if (raw != null) port.send(raw);
  }
}

class _PendingUpload {
  final StreamController<double> controller;
  int? fileId;

  _PendingUpload(this.controller);
}

class RealTgClient implements TgClient {
  RealTgClient({required this.credentials}) : _td = TdLib.load();

  final TgCredentials credentials;
  final TdLib _td;

  final _steps = StreamController<AuthStep>.broadcast();
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _uploadsByMessage = <int, _PendingUpload>{};
  final _uploadsByFile = <int, _PendingUpload>{};

  int _clientId = -1;
  int _extraSeq = 0;
  String _dbDir = '';
  bool _started = false;
  Isolate? _isolate;
  ReceivePort? _port;
  int? _savedMessagesChat;

  @override
  Stream<AuthStep> get authSteps => _steps.stream;

  @override
  Future<void> initialize() async {
    if (_started) return;
    _started = true;

    _td.execute({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': 1});
    final support = await getApplicationSupportDirectory();
    _dbDir = p.join(support.path, 'tdlib');

    final port = ReceivePort();
    _port = port;
    port.listen(_onRaw);
    _isolate = await Isolate.spawn(_receiveLoop, port.sendPort);

    _clientId = _td.createClientId();
    _kick();
  }

  void _kick() =>
      _td.send(_clientId, {'@type': 'getOption', 'name': 'version'});

  void _onRaw(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> event;
    try {
      event = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final clientId = event['@client_id'];
    if (clientId is int && clientId != _clientId) return;
    _handle(event);
  }

  void _handle(Map<String, dynamic> event) {
    final extra = event['@extra'];
    if (extra is int) {
      final completer = _pending.remove(extra);
      if (completer != null) {
        if (event['@type'] == 'error') {
          completer.completeError(tdErrorToException(event));
        } else {
          completer.complete(event);
        }
      }
      return;
    }

    switch (event['@type']) {
      case 'updateAuthorizationState':
        final state = event['authorization_state'];
        if (state is Map<String, dynamic>) _onAuthState(state);
      case 'updateFile':
        final file = event['file'];
        if (file is Map<String, dynamic>) _onFile(file);
      case 'updateMessageSendSucceeded':
        _finishUpload(event['old_message_id'], null);
      case 'updateMessageSendFailed':
        final err = event['error'];
        _finishUpload(
          event['old_message_id'],
          err is Map<String, dynamic>
              ? tdErrorToException(err)
              : const TdError(0, 'Upload failed'),
        );
    }
  }

  void _onAuthState(Map<String, dynamic> state) {
    final type = state['@type'] as String? ?? '';
    switch (type) {
      case 'authorizationStateWaitTdlibParameters':
        _td.send(_clientId, {
          '@type': 'setTdlibParameters',
          'use_test_dc': false,
          'database_directory': _dbDir,
          'files_directory': '',
          'database_encryption_key': '',
          'use_file_database': true,
          'use_chat_info_database': true,
          'use_message_database': true,
          'use_secret_chats': false,
          'api_id': credentials.apiId,
          'api_hash': credentials.apiHash,
          'system_language_code': 'en',
          'device_model': 'SannDrive',
          'system_version': '',
          'application_version': '1.0.0',
        });
      case 'authorizationStateWaitEncryptionKey':
        _td.send(_clientId, {
          '@type': 'checkDatabaseEncryptionKey',
          'encryption_key': '',
        });
      case 'authorizationStateClosed':
        _savedMessagesChat = null;
        _clientId = _td.createClientId();
        _kick();
      default:
        final step = mapAuthorizationState(type);
        if (step != null && !_steps.isClosed) _steps.add(step);
    }
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> request) {
    final extra = ++_extraSeq;
    final completer = Completer<Map<String, dynamic>>();
    _pending[extra] = completer;
    _td.send(_clientId, {...request, '@extra': extra});
    return completer.future;
  }

  @override
  Future<void> setPhone(String phone) => _request({
        '@type': 'setAuthenticationPhoneNumber',
        'phone_number': phone,
      });

  @override
  Future<void> checkCode(String code) =>
      _request({'@type': 'checkAuthenticationCode', 'code': code});

  @override
  Future<void> checkPassword(String password) =>
      _request({'@type': 'checkAuthenticationPassword', 'password': password});

  @override
  Future<void> logOut() => _request({'@type': 'logOut'});

  Future<int> _savedMessagesChatId() async {
    final cached = _savedMessagesChat;
    if (cached != null) return cached;
    final me = await _request({'@type': 'getMe'});
    final chat = await _request({
      '@type': 'createPrivateChat',
      'user_id': me['id'],
      'force': false,
    });
    final id = (chat['id'] as num).toInt();
    _savedMessagesChat = id;
    return id;
  }

  @override
  Stream<double> upload(String path, {String? caption}) {
    final controller = StreamController<double>();
    _startUpload(path, caption, controller);
    return controller.stream;
  }

  Future<void> _startUpload(
    String path,
    String? caption,
    StreamController<double> controller,
  ) async {
    try {
      final chatId = await _savedMessagesChatId();
      final message = await _request({
        '@type': 'sendMessage',
        'chat_id': chatId,
        'input_message_content': {
          '@type': 'inputMessageDocument',
          'document': {'@type': 'inputFileLocal', 'path': path},
          if (caption != null && caption.isNotEmpty)
            'caption': {'@type': 'formattedText', 'text': caption},
        },
      });
      final pending = _PendingUpload(controller);
      final messageId = (message['id'] as num?)?.toInt();
      if (messageId != null) _uploadsByMessage[messageId] = pending;
      final fileId = ((message['content']
              as Map<String, dynamic>?)?['document']
          as Map<String, dynamic>?)?['document'] as Map<String, dynamic>?;
      final id = (fileId?['id'] as num?)?.toInt();
      if (id != null) {
        pending.fileId = id;
        _uploadsByFile[id] = pending;
      }
      controller.add(0.0);
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  void _onFile(Map<String, dynamic> file) {
    final id = (file['id'] as num?)?.toInt();
    if (id == null) return;
    final pending = _uploadsByFile[id];
    if (pending == null || pending.controller.isClosed) return;
    final remote = file['remote'] as Map<String, dynamic>?;
    if (remote == null) return;
    final uploaded = (remote['uploaded_size'] as num?)?.toDouble() ?? 0;
    var total = (file['size'] as num?)?.toDouble() ?? 0;
    if (total <= 0) total = (file['expected_size'] as num?)?.toDouble() ?? 0;
    if (total > 0) {
      pending.controller.add((uploaded / total).clamp(0.0, 1.0));
    }
  }

  void _finishUpload(dynamic oldMessageId, Exception? error) {
    final id = (oldMessageId as num?)?.toInt();
    if (id == null) return;
    final pending = _uploadsByMessage.remove(id);
    if (pending == null) return;
    final fileId = pending.fileId;
    if (fileId != null) _uploadsByFile.remove(fileId);
    if (pending.controller.isClosed) return;
    if (error == null) {
      pending.controller.add(1.0);
    } else {
      pending.controller.addError(error);
    }
    pending.controller.close();
  }

  // TODO(pass 2): feed this into the local drive index once the native
  // library ships, so the drive view reflects what is really in Telegram.
  Future<List<Map<String, dynamic>>> listDocuments({int limit = 100}) async {
    final chatId = await _savedMessagesChatId();
    final found = await _request({
      '@type': 'searchChatMessages',
      'chat_id': chatId,
      'query': '',
      'from_message_id': 0,
      'offset': 0,
      'limit': limit,
      'filter': {'@type': 'searchMessagesFilterDocument'},
    });
    final messages = found['messages'];
    if (messages is! List) return const [];
    return [
      for (final m in messages)
        if (m is Map<String, dynamic>) m,
    ];
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _port?.close();
    _port = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(const TdError(0, 'Client disposed'));
      }
    }
    _pending.clear();
    for (final pending in _uploadsByMessage.values) {
      if (!pending.controller.isClosed) pending.controller.close();
    }
    _uploadsByMessage.clear();
    _uploadsByFile.clear();
    _steps.close();
  }
}
