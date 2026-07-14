import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/core/env.dart';
import '../../shared/services/telegram/auth.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final f = _fieldsFor(auth.step);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GridBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandMark(size: 68)),
                      const SizedBox(height: AppSpace.base),
                      Center(
                        child: Text(Env.appName,
                            style: AppText.wordmark(context, size: 22)),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(Env.tagline, style: AppText.meta(context)),
                      ),
                      const SizedBox(height: AppSpace.section),
                      Text(f.title,
                          textAlign: TextAlign.center,
                          style: AppText.screenTitle(context)),
                      const SizedBox(height: AppSpace.half),
                      Text(f.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              height: 1.5,
                              color: scheme.onSurface.withOpacity(0.65))),
                      const SizedBox(height: AppSpace.hero),
                      TextField(
                        controller: _field,
                        autofocus: true,
                        obscureText: f.obscure,
                        keyboardType: f.keyboard,
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _submit(auth.step),
                        decoration: InputDecoration(hintText: f.hint),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 14),
                        Text(auth.error!,
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: scheme.error, fontSize: 13)),
                      ],
                      const SizedBox(height: AppSpace.hero),
                      FilledButton.tonal(
                        onPressed: auth.busy ? null : () => _submit(auth.step),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: auth.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(f.action),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
