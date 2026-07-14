enum AuthStep { initial, waitPhone, waitCode, waitPassword, ready, loggingOut }

class AuthState {
  final AuthStep step;
  final bool busy;
  final String? error;
  final String? phone;

  const AuthState({
    this.step = AuthStep.initial,
    this.busy = false,
    this.error,
    this.phone,
  });

  bool get authenticated => step == AuthStep.ready;

  AuthState copyWith({
    AuthStep? step,
    bool? busy,
    String? error,
    bool clearError = false,
    String? phone,
  }) {
    return AuthState(
      step: step ?? this.step,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      phone: phone ?? this.phone,
    );
  }
}
