import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/telegram/credentials.dart';
import '../services/telegram/tdlib_ffi.dart';

enum EngineMode { loading, onboarding, demo, real }

const engineUnavailableNotice =
    'Telegram engine not bundled in this build yet — running in demo mode';

class SetupState {
  final EngineMode mode;
  final TgCredentials? credentials;
  final String? notice;

  const SetupState({
    this.mode = EngineMode.loading,
    this.credentials,
    this.notice,
  });

  SetupState copyWith({
    EngineMode? mode,
    TgCredentials? credentials,
    String? notice,
    bool clearNotice = false,
  }) {
    return SetupState(
      mode: mode ?? this.mode,
      credentials: credentials ?? this.credentials,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

final credentialsStoreProvider =
    Provider<CredentialsStore>((ref) => CredentialsStore());

final setupControllerProvider =
    StateNotifierProvider<SetupController, SetupState>((ref) {
  return SetupController(ref.watch(credentialsStoreProvider));
});

class SetupController extends StateNotifier<SetupState> {
  SetupController(this._store, {bool Function()? engineAvailable})
      : _engineAvailable = engineAvailable ?? (() => TdLib.isAvailable),
        super(const SetupState()) {
    _load();
  }

  final CredentialsStore _store;
  final bool Function() _engineAvailable;

  Future<void> _load() async {
    final creds = await _store.load();
    if (!mounted) return;
    if (creds == null) {
      state = state.copyWith(mode: EngineMode.onboarding);
    } else {
      _activate(creds);
    }
  }

  void _activate(TgCredentials creds) {
    if (_engineAvailable()) {
      state = state.copyWith(mode: EngineMode.real, credentials: creds);
    } else {
      state = state.copyWith(
        mode: EngineMode.demo,
        credentials: creds,
        notice: engineUnavailableNotice,
      );
    }
  }

  Future<void> saveCredentials(TgCredentials creds) async {
    await _store.save(creds);
    if (!mounted) return;
    _activate(creds);
  }

  void useDemo() {
    state = state.copyWith(mode: EngineMode.demo);
  }

  void noteEngineUnavailable() {
    if (state.mode == EngineMode.demo) return;
    state = state.copyWith(
      mode: EngineMode.demo,
      notice: engineUnavailableNotice,
    );
  }
}
