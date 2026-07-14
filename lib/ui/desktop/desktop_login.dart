import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/core/env.dart';
import '../../shared/services/telegram/auth.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final p = _promptFor(auth.step);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                const Positioned.fill(child: GridBackdrop()),
                Padding(
                  padding: const EdgeInsets.all(56),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandMark(size: 44),
                          const SizedBox(width: 12),
                          Text(Env.appName,
                              style: AppText.wordmark(context, size: 22)),
                        ],
                      ),
                      const SizedBox(height: AppSpace.section),
                      Text('Unlimited cloud,\nyours by design.',
                          style: GoogleFonts.raleway(
                              fontSize: 40,
                              height: 1.15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpace.base),
                      SizedBox(
                        width: 400,
                        child: Text(
                          'SannDrive keeps your files in your own Telegram cloud — up to 2 GB each, no storage cap, no middleman.',
                          style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.65),
                              fontSize: 15,
                              height: 1.5),
                        ),
                      ),
                      const SizedBox(height: AppSpace.hero),
                      const Wrap(
                        spacing: AppSpace.half,
                        runSpacing: AppSpace.half,
                        children: [
                          Chip(label: Text('2 GB per file')),
                          Chip(label: Text('No storage cap')),
                          Chip(label: Text('Yours end to end')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: scheme.outlineVariant),
          Expanded(
            flex: 4,
            child: Container(
              color: scheme.surfaceContainer,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(p.title, style: AppText.screenTitle(context)),
                      const SizedBox(height: AppSpace.half),
                      Text(p.subtitle,
                          style: TextStyle(
                              height: 1.5,
                              color: scheme.onSurface.withOpacity(0.65))),
                      const SizedBox(height: AppSpace.hero),
                      TextField(
                        controller: _field,
                        autofocus: true,
                        obscureText: p.obscure,
                        onSubmitted: (_) => _submit(auth.step),
                        decoration: InputDecoration(
                          hintText: p.hint,
                          fillColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Text(auth.error!,
                            style:
                                TextStyle(color: scheme.error, fontSize: 13)),
                      ],
                      const SizedBox(height: AppSpace.page),
                      FilledButton.tonal(
                        onPressed: auth.busy ? null : () => _submit(auth.step),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: auth.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(p.action),
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
      return const _Prompt('Sign in to SannDrive',
          'Enter your Telegram phone number to begin.', '+91 98765 43210',
          'Send code');
  }
}
