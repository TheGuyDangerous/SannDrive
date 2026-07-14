import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/core/env.dart';
import '../../theme/app_theme.dart';

class DesktopHome extends ConsumerStatefulWidget {
  const DesktopHome({super.key});

  @override
  ConsumerState<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends ConsumerState<DesktopHome> {
  int _section = 0;

  static const _nav = [
    (icon: Icons.folder_rounded, label: 'My Drive'),
    (icon: Icons.photo_library_rounded, label: 'Photos'),
    (icon: Icons.schedule_rounded, label: 'Recent'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accent2]),
                    ),
                    child: const Icon(Icons.cloud_rounded,
                        color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Text(Env.appName,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 22),
                for (var i = 0; i < _nav.length; i++)
                  _NavItem(
                    icon: _nav[i].icon,
                    label: _nav[i].label,
                    active: _section == i,
                    onTap: () => setState(() => _section = i),
                  ),
                const Spacer(),
                _NavItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign out',
                  active: false,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).logOut(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text(_nav[_section].label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Upload'),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 64, color: AppColors.muted),
                        SizedBox(height: 16),
                        Text('Nothing here yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('Drop files or hit Upload to store them in your Telegram cloud.',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.surfaceHi : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 19,
                    color: active ? AppColors.accent : AppColors.muted),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        color: active ? AppColors.text : AppColors.muted,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
