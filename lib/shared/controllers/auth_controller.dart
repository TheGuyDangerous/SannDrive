import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/telegram/auth.dart';
import '../services/telegram/real_tg_client.dart';
import '../services/telegram/tdlib_ffi.dart';
import '../services/telegram/tg_client.dart';
import 'setup_controller.dart';

final tgClientProvider = Provider<TgClient>((ref) {
  final mode = ref.watch(setupControllerProvider.select((s) => s.mode));
  final creds =
      ref.watch(setupControllerProvider.select((s) => s.credentials));

  if (mode == EngineMode.real && creds != null) {
    try {
      final client = RealTgClient(credentials: creds);
      ref.onDispose(client.dispose);
      return client;
    } on TdlibUnavailable {
      Future.microtask(
          ref.read(setupControllerProvider.notifier).noteEngineUnavailable);
    }
  }

  final client = FakeTgClient();
  ref.onDispose(client.dispose);
  return client;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(tgClientProvider));
});

class AuthController extends StateNotifier<AuthState> {
  final TgClient _client;
  late final StreamSubscription<AuthStep> _sub;

  AuthController(this._client) : super(const AuthState()) {
    _sub = _client.authSteps.listen((step) {
      state = state.copyWith(step: step, busy: false, clearError: true);
    });
    _client.initialize().catchError((Object e) {
      if (mounted) state = state.copyWith(busy: false, error: e.toString());
    });
  }

  Future<void> submitPhone(String phone) =>
      _run(() => _client.setPhone(phone), phone: phone);

  Future<void> submitCode(String code) => _run(() => _client.checkCode(code));

  Future<void> submitPassword(String password) =>
      _run(() => _client.checkPassword(password));

  Future<void> logOut() => _run(_client.logOut);

  Future<void> _run(Future<void> Function() action, {String? phone}) async {
    state = state.copyWith(busy: true, clearError: true, phone: phone);
    try {
      await action();
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
