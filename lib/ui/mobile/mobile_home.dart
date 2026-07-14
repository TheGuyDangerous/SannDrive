import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/core/env.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';
import '../common/empty_state.dart';
import '../common/section_card.dart';

class MobileHome extends ConsumerStatefulWidget {
  const MobileHome({super.key});

  @override
  ConsumerState<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends ConsumerState<MobileHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpace.page,
        title: Row(
          children: [
            const BrandMark(size: 30),
            const SizedBox(width: 10),
            Text(Env.appName, style: AppText.wordmark(context)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _DriveTab(),
          _PhotosTab(),
          _RecentTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.folder_2), label: 'My Drive'),
          NavigationDestination(icon: Icon(Iconsax.gallery), label: 'Photos'),
          NavigationDestination(icon: Icon(Iconsax.clock), label: 'Recent'),
          NavigationDestination(
              icon: Icon(Iconsax.setting_2), label: 'Settings'),
        ],
      ),
    );
  }
}

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.page, AppSpace.base, AppSpace.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.screenTitle(context)),
          const SizedBox(height: AppSpace.base),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DriveTab extends StatelessWidget {
  const _DriveTab();

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'My Drive',
      child: SkeletonThenEmpty(
        empty: EmptyState(
          title: 'Your drive is empty',
          subtitle: 'Upload a file to keep it in your Telegram cloud.',
          action: FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Iconsax.document_upload, size: 18),
            label: const Text('Upload a file'),
          ),
        ),
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab();

  @override
  Widget build(BuildContext context) {
    return const _TabScaffold(
      title: 'Photos',
      child: EmptyState(
        title: 'No photos yet',
        subtitle: 'Photos and videos you upload will show up here.',
      ),
    );
  }
}

class _RecentTab extends StatelessWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context) {
    return const _TabScaffold(
      title: 'Recent',
      child: EmptyState(
        title: 'No recent activity',
        subtitle: 'Files you open or upload will appear here.',
      ),
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(authControllerProvider).phone;
    return _TabScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.section),
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
              onTap: () => ref.read(authControllerProvider.notifier).logOut(),
            ),
          ),
        ],
      ),
    );
  }
}
