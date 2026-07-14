import 'package:flutter_test/flutter_test.dart';
import 'package:sanndrive/shared/controllers/setup_controller.dart';
import 'package:sanndrive/shared/services/telegram/auth.dart';
import 'package:sanndrive/shared/services/telegram/credentials.dart';
import 'package:sanndrive/shared/services/telegram/real_tg_client.dart';
import 'package:sanndrive/shared/services/telegram/tg_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
