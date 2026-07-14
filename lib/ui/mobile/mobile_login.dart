import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/core/env.dart';
import '../../shared/services/telegram/auth.dart';
import '../../theme/app_theme.dart';

class MobileLogin extends ConsumerStatefulWidget {
  const MobileLogin({super.key});

  @override
  ConsumerState<MobileLogin> createState() => _MobileLoginState();
}

class _MobileLoginState extends ConsumerState<MobileLogin> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit(AuthStep step) {
    final v = _field.text.trim();
    if (v.isEmpty) return;
    final c = ref.read(authControllerProvider.notifier);
    switch (step) {
      case AuthStep.waitPhone:
        c.submitPhone(v);
      case AuthStep.waitCode:
        c.submitCode(v);
      case AuthStep.waitPassword:
        c.submitPassword(v);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.step != next.step) _field.clear();
    });
    final auth = ref.watch(authControllerProvider);
    final f = _fieldsFor(auth.step);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Brand(),
                const SizedBox(height: 36),
                Text(f.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(f.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 28),
                TextField(
                  controller: _field,
                  autofocus: true,
                  obscureText: f.obscure,
                  keyboardType: f.keyboard,
                  onSubmitted: (_) => _submit(auth.step),
                  decoration: InputDecoration(hintText: f.hint),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 14),
                  Text(auth.error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: auth.busy ? null : () => _submit(auth.step),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(f.action),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accent2]),
          ),
          child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 14),
        const Text(Env.appName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(Env.tagline, style: TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class _Fields {
  final String title, subtitle, hint, action;
  final bool obscure;
  final TextInputType keyboard;
  const _Fields(this.title, this.subtitle, this.hint, this.action,
      {this.obscure = false, this.keyboard = TextInputType.text});
}

_Fields _fieldsFor(AuthStep step) {
  switch (step) {
    case AuthStep.waitCode:
      return const _Fields('Enter the code',
          'We sent a login code to your Telegram app.', 'Login code', 'Verify',
          keyboard: TextInputType.number);
    case AuthStep.waitPassword:
      return const _Fields('Two-step password',
          'Your account is protected by a cloud password.', 'Password',
          'Unlock',
          obscure: true);
    default:
      return const _Fields(
          'Sign in',
          'Use your Telegram phone number. Your files stay in your own Telegram cloud.',
          '+91 98765 43210',
          'Send code',
          keyboard: TextInputType.phone);
  }
}
