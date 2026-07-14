import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/controllers/auth_controller.dart';
import 'shared/core/env.dart';
import 'shared/core/form_factor.dart';
import 'shared/services/telegram/auth.dart';
import 'theme/app_theme.dart';
import 'ui/common/brand_mark.dart';
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

    final Widget child;
    if (auth.step == AuthStep.initial) {
      child = const Scaffold(body: Center(child: PulsingBrandMark()));
    } else if (auth.authenticated) {
      child = desktop ? const DesktopHome() : const MobileHome();
    } else {
      child = desktop ? const DesktopLogin() : const MobileLogin();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
