import 'package:flutter_test/flutter_test.dart';
import 'package:sanndrive/shared/controllers/auth_controller.dart';
import 'package:sanndrive/shared/controllers/drive_controller.dart';
import 'package:sanndrive/shared/controllers/setup_controller.dart';
import 'package:sanndrive/shared/services/index/drive_index.dart';
import 'package:sanndrive/shared/services/telegram/auth.dart';
import 'package:sanndrive/shared/services/telegram/credentials.dart';
import 'package:sanndrive/shared/services/telegram/real_tg_client.dart';
import 'package:sanndrive/shared/services/telegram/tg_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> documentMessage({
  required int id,
  required String fileName,
  int size = 1024,
  int date = 1752500000,
  String? caption,
}) =>
    {
      '@type': 'message',
      'id': id,
      'date': date,
      'content': {
        '@type': 'messageDocument',
        'document': {
          '@type': 'document',
          'file_name': fileName,
          'document': {'@type': 'file', 'id': 1, 'size': size},
        },
        if (caption != null)
          'caption': {'@type': 'formattedText', 'text': caption},
      },
    };

Future<void> waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  var waited = Duration.zero;
  const step = Duration(milliseconds: 10);
  while (!condition()) {
    if (waited >= timeout) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(step);
    waited += step;
  }
}

void main() {
  test('credentials store saves, loads and clears', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CredentialsStore();
    expect(await store.load(), isNull);
    expect(await store.hasCredentials, isFalse);

    await store.save(const TgCredentials(
        apiId: 12345, apiHash: '0123456789abcdef0123456789abcdef'));
    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.apiId, 12345);
    expect(loaded.apiHash, '0123456789abcdef0123456789abcdef');
    expect(await store.hasCredentials, isTrue);

    await store.clear();
    expect(await store.load(), isNull);
  });

  test('credential input validation', () {
    expect(parseApiId('12345'), 12345);
    expect(parseApiId(' 42 '), 42);
    expect(parseApiId('0'), isNull);
    expect(parseApiId('-3'), isNull);
    expect(parseApiId('abc'), isNull);

    expect(isValidApiHash('0123456789abcdef0123456789ABCDEF'), isTrue);
    expect(isValidApiHash(' 0123456789abcdef0123456789abcdef '), isTrue);
    expect(isValidApiHash('too-short'), isFalse);
    expect(isValidApiHash(''), isFalse);
  });

  test('no stored credentials leads to onboarding', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = SetupController(CredentialsStore());
    await waitUntil(() => controller.state.mode != EngineMode.loading);
    expect(controller.state.mode, EngineMode.onboarding);

    controller.useDemo();
    expect(controller.state.mode, EngineMode.demo);
    expect(controller.state.notice, isNull);
    controller.dispose();
  });

  test('credentials without the native library fall back to demo with notice',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller =
        SetupController(CredentialsStore(), engineAvailable: () => false);
    await waitUntil(() => controller.state.mode != EngineMode.loading);
    expect(controller.state.mode, EngineMode.onboarding);

    await controller.saveCredentials(const TgCredentials(
        apiId: 12345, apiHash: '0123456789abcdef0123456789abcdef'));
    expect(controller.state.mode, EngineMode.demo);
    expect(controller.state.notice, engineUnavailableNotice);
    controller.dispose();
  });

  test('credentials with the native library available go real', () async {
    SharedPreferences.setMockInitialValues({
      'tg_api_id': 12345,
      'tg_api_hash': '0123456789abcdef0123456789abcdef',
    });
    final controller =
        SetupController(CredentialsStore(), engineAvailable: () => true);
    await waitUntil(() => controller.state.mode != EngineMode.loading);
    expect(controller.state.mode, EngineMode.real);
    expect(controller.state.credentials?.apiId, 12345);
    controller.dispose();
  });

  test('TDLib authorization states map onto our auth steps', () {
    expect(mapAuthorizationState('authorizationStateWaitPhoneNumber'),
        AuthStep.waitPhone);
    expect(mapAuthorizationState('authorizationStateWaitCode'),
        AuthStep.waitCode);
    expect(mapAuthorizationState('authorizationStateWaitPassword'),
        AuthStep.waitPassword);
    expect(mapAuthorizationState('authorizationStateReady'), AuthStep.ready);
    expect(mapAuthorizationState('authorizationStateLoggingOut'),
        AuthStep.loggingOut);
    expect(
        mapAuthorizationState('authorizationStateWaitTdlibParameters'), isNull);
    expect(mapAuthorizationState('authorizationStateClosed'), isNull);
  });

  test('TDLib errors map to exceptions, including FLOOD_WAIT', () {
    final flood = tdErrorToException(
        {'code': 429, 'message': 'Too Many Requests: retry after 17'});
    expect(flood, isA<FloodWaitException>());
    expect((flood as FloodWaitException).seconds, 17);

    final plain =
        tdErrorToException({'code': 400, 'message': 'PHONE_NUMBER_INVALID'});
    expect(plain, isA<TdError>());
    expect(plain.toString(), 'PHONE_NUMBER_INVALID');
  });

  test('saved messages documents map into drive items', () {
    final item = driveItemFromMessage(documentMessage(
      id: 987,
      fileName: 'Quarterly report.pdf',
      size: 2048,
      date: 1752500000,
    ));

    expect(item, isNotNull);
    expect(item!.id, 'tg-987');
    expect(item.name, 'Quarterly report.pdf');
    expect(item.size, 2048);
    expect(item.ext, 'pdf');
    expect(item.tgMessageId, 987);
    expect(item.captionTag, isNull);
    expect(item.parentId, isNull);
    expect(item.modified,
        DateTime.fromMillisecondsSinceEpoch(1752500000 * 1000));
  });

  test('a SannDrive caption tag overrides the document filename', () {
    final item = driveItemFromMessage(documentMessage(
      id: 1,
      fileName: 'IMG_2041.pdf',
      caption: 'backup\n#sanndrive Tax statement 2026.pdf',
    ));

    expect(item!.name, 'Tax statement 2026.pdf');
    expect(item.ext, 'pdf');
    expect(item.captionTag, '#sanndrive Tax statement 2026.pdf');

    final bare = driveItemFromMessage(documentMessage(
      id: 2,
      fileName: 'notes.txt',
      caption: '#sanndrive',
    ));
    expect(bare!.name, 'notes.txt');
    expect(bare.captionTag, '#sanndrive');
  });

  test('non-document messages are skipped', () {
    expect(driveItemFromMessage({'@type': 'message', 'id': 3}), isNull);
    expect(
        driveItemFromMessage({
          '@type': 'message',
          'id': 4,
          'content': {'@type': 'messageText'},
        }),
        isNull);
  });

  test('importRemote upserts fetched documents into the drive index',
      () async {
    sqfliteFfiInit();
    final index =
        DriveIndex(factory: databaseFactoryFfi, dbPath: inMemoryDatabasePath);
    final controller = DriveController(index, seed: false);
    await waitUntil(() => !controller.state.loading);

    final first = driveItemFromMessage(
        documentMessage(id: 10, fileName: 'a.pdf', size: 5))!;
    final second = driveItemFromMessage(
        documentMessage(id: 11, fileName: 'b.txt', size: 7))!;
    await controller.importRemote([first, second]);
    expect([for (final i in controller.state.items) i.id],
        containsAll(['tg-10', 'tg-11']));

    final renamed = driveItemFromMessage(documentMessage(
        id: 10, fileName: 'a.pdf', caption: '#sanndrive renamed.pdf'))!;
    await controller.importRemote([renamed]);
    expect(controller.state.items, hasLength(2));
    expect(
        controller.state.items.firstWhere((i) => i.id == 'tg-10').name,
        'renamed.pdf');

    controller.dispose();
    await index.close();
  });

  test('reaching ready triggers the drive sync hook once per login',
      () async {
    final client = FakeTgClient();
    var syncs = 0;
    final controller = AuthController(client, onReady: () => syncs++);
    await waitUntil(() => controller.state.step == AuthStep.waitPhone);

    await controller.submitPhone('+15550001111');
    await waitUntil(() => controller.state.step == AuthStep.waitCode);
    await controller.submitCode('11111');
    await waitUntil(() => controller.state.step == AuthStep.ready);
    expect(syncs, 1);

    await controller.logOut();
    await waitUntil(() => controller.state.step == AuthStep.waitPhone);
    expect(syncs, 1);

    controller.dispose();
    client.dispose();
  });
}
