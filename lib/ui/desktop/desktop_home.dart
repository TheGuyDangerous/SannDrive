import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/core/env.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';
import '../common/empty_state.dart';
import '../common/section_card.dart';

class DesktopHome extends ConsumerStatefulWidget {
  const DesktopHome({super.key});

  @override
  ConsumerState<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends ConsumerState<DesktopHome> {
  int _section = 0;

  static const _nav = [
    (icon: Iconsax.folder_2, label: 'My Drive'),
    (icon: Iconsax.gallery, label: 'Photos'),
    (icon: Iconsax.clock, label: 'Recent'),
    (icon: Iconsax.setting_2, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 248,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              border: Border(right: BorderSide(color: scheme.outlineVariant)),
            ),
            padding: const EdgeInsets.all(AppSpace.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.half, vertical: AppSpace.half),
                  child: Row(
                    children: [
                      const BrandMark(size: 32),
                      const SizedBox(width: 10),
                      Text(Env.appName, style: AppText.wordmark(context)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.base),
                for (var i = 0; i < _nav.length; i++)
                  _NavItem(
                    icon: _nav[i].icon,
                    label: _nav[i].label,
                    active: _section == i,
                    onTap: () => setState(() => _section = i),
                  ),
                const Spacer(),
                _NavItem(
                  icon: Iconsax.logout,
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
                  height: 64,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.hero),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      IconBadge(icon: _nav[_section].icon),
                      const SizedBox(width: 12),
                      Text(_nav[_section].label,
                          style: AppText.sectionTitle(context)),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () {},
                        icon: const Icon(Iconsax.document_upload, size: 18),
                        label: const Text('Upload'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.hero),
                    child: IndexedStack(
                      index: _section,
                      children: const [
                        _DriveSection(),
                        EmptyState(
                          title: 'No photos yet',
                          subtitle:
                              'Photos and videos you upload will show up here.',
                        ),
                        EmptyState(
                          title: 'No recent activity',
                          subtitle:
                              'Files you open or upload will appear here.',
                        ),
                        _SettingsSection(),
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

class _DriveSection extends StatelessWidget {
  const _DriveSection();

  @override
  Widget build(BuildContext context) {
    return const SkeletonThenEmpty(
      empty: EmptyState(
        title: 'Nothing here yet',
        subtitle:
            'Drop files or hit Upload to store them in your Telegram cloud.',
      ),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(authControllerProvider).phone;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          children: [
            const SectionCard(
              icon: Iconsax.info_circle,
              title: 'About',
              padding: EdgeInsets.only(bottom: AppSpace.half),
              child: IconBadgeRow(
                icon: Iconsax.cloud,
                title: Env.appName,
                subtitle: 'Version 1.0.0 · ${Env.tagline}',
              ),
            ),
            const SizedBox(height: AppSpace.base),
            const SectionCard(
              icon: Iconsax.driver,
              title: 'Storage',
              padding: EdgeInsets.only(bottom: AppSpace.half),
              child: IconBadgeRow(
                icon: Iconsax.folder_cloud,
                title: 'Telegram cloud',
                subtitle: 'Up to 2 GB per file · no storage cap',
              ),
            ),
            const SizedBox(height: AppSpace.base),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.half),
              child: IconBadgeRow(
                icon: Iconsax.logout,
                title: 'Sign out',
                subtitle: phone,
                onTap: () =>
                    ref.read(authControllerProvider.notifier).logOut(),
              ),
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active
            ? scheme.primary.withOpacity(0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 19,
                    color: active
                        ? scheme.primary
                        : scheme.onSurface.withOpacity(0.65)),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        color: active
                            ? scheme.onSurface
                            : scheme.onSurface.withOpacity(0.65),
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
