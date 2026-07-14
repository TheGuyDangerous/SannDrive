import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/controllers/auth_controller.dart';
import 'shared/core/env.dart';
import 'shared/core/form_factor.dart';
import 'shared/services/telegram/auth.dart';
import 'theme/app_theme.dart';
import 'ui/desktop/desktop_home.dart';
import 'ui/desktop/desktop_login.dart';
import 'ui/mobile/mobile_home.dart';
import 'ui/mobile/mobile_login.dart';

class SannDriveApp extends StatelessWidget {
  const SannDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootGate(),
    );
  }
}

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final desktop = isDesktopPlatform;

    if (auth.step == AuthStep.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.authenticated) {
      return desktop ? const DesktopHome() : const MobileHome();
    }
    return desktop ? const DesktopLogin() : const MobileLogin();
  }
}
