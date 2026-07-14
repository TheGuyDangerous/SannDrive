import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class TdlibUnavailable implements Exception {
  final String message;

  const TdlibUnavailable(
      [this.message = 'The TDLib native library is not bundled in this build']);

  @override
  String toString() => message;
}

typedef _CreateClientIdC = Int32 Function();
typedef _CreateClientIdDart = int Function();
typedef _SendC = Void Function(Int32 clientId, Pointer<Utf8> request);
typedef _SendDart = void Function(int clientId, Pointer<Utf8> request);
typedef _ReceiveC = Pointer<Utf8> Function(Double timeout);
typedef _ReceiveDart = Pointer<Utf8> Function(double timeout);
typedef _ExecuteC = Pointer<Utf8> Function(Pointer<Utf8> request);
typedef _ExecuteDart = Pointer<Utf8> Function(Pointer<Utf8> request);

class TdLib {
  TdLib._(DynamicLibrary lib)
      : _createClientId = lib
            .lookupFunction<_CreateClientIdC, _CreateClientIdDart>(
                'td_create_client_id'),
        _send = lib.lookupFunction<_SendC, _SendDart>('td_send'),
        _receive = lib.lookupFunction<_ReceiveC, _ReceiveDart>('td_receive'),
        _execute = lib.lookupFunction<_ExecuteC, _ExecuteDart>('td_execute');

  final _CreateClientIdDart _createClientId;
  final _SendDart _send;
  final _ReceiveDart _receive;
  final _ExecuteDart _execute;

  static TdLib? _instance;
  static bool _attempted = false;

  static TdLib? tryLoad() {
    if (_attempted) return _instance;
    _attempted = true;
    try {
      _instance = TdLib._(_open());
    } catch (_) {
      _instance = null;
    }
    return _instance;
  }

  static TdLib load() {
    final td = tryLoad();
    if (td == null) throw const TdlibUnavailable();
    return td;
  }

  static bool get isAvailable => tryLoad() != null;

  static DynamicLibrary _open() {
    if (Platform.isWindows) return DynamicLibrary.open('tdjson.dll');
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('libtdjson.dylib');
    }
    return DynamicLibrary.open('libtdjson.so');
  }

  int createClientId() => _createClientId();

  void send(int clientId, Map<String, dynamic> request) {
    final ptr = jsonEncode(request).toNativeUtf8();
    try {
      _send(clientId, ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  String? receiveRaw(double timeout) {
    final ptr = _receive(timeout);
    if (ptr == nullptr) return null;
    return ptr.toDartString();
  }

  Map<String, dynamic>? execute(Map<String, dynamic> request) {
    final ptr = jsonEncode(request).toNativeUtf8();
    try {
      final out = _execute(ptr);
      if (out == nullptr) return null;
      return jsonDecode(out.toDartString()) as Map<String, dynamic>;
    } finally {
      malloc.free(ptr);
    }
  }
}
