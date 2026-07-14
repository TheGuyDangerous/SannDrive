import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/services/telegram/auth.dart';
import '../../theme/desktop_theme.dart';

class DesktopLogin extends ConsumerStatefulWidget {
  const DesktopLogin({super.key});

  @override
  ConsumerState<DesktopLogin> createState() => _DesktopLoginState();
}

class _DesktopLoginState extends ConsumerState<DesktopLogin> {
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
    final p = _promptFor(auth.step);

    return Theme(
      data: DesktopTheme.dark,
      child: Builder(builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return Scaffold(
          body: Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.fromLTRB(36, 40, 36, 36),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child:
                          Icon(Iconsax.cloud, size: 30, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'SannDrive',
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      p.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    p.title,
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _field,
                    autofocus: true,
                    obscureText: p.obscure,
                    onSubmitted: (_) => _submit(auth.step),
                    decoration: InputDecoration(hintText: p.hint),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      auth.error!,
                      style: TextStyle(color: scheme.error, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.busy ? null : () => _submit(auth.step),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: auth.busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(p.action),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Prompt {
  final String title, subtitle, hint, action;
  final bool obscure;
  const _Prompt(this.title, this.subtitle, this.hint, this.action,
      {this.obscure = false});
}

_Prompt _promptFor(AuthStep step) {
  switch (step) {
    case AuthStep.waitCode:
      return const _Prompt('Enter your code',
          'Check your Telegram app for the login code.', 'Login code', 'Verify');
    case AuthStep.waitPassword:
      return const _Prompt('Two-step password',
          'Your account has a cloud password enabled.', 'Password', 'Unlock',
          obscure: true);
    default:
      return const _Prompt(
          'Sign in with Telegram',
          'Your files live in your own Telegram cloud.\nEnter your phone number to begin.',
          '+91 98765 43210',
          'Send code');
  }
}
