import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/controllers/drive_controller.dart';
import '../../shared/core/env.dart';
import '../../shared/core/format.dart';
import '../../shared/models/drive_item.dart';
import '../../shared/services/upload/upload_queue.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';
import '../common/empty_state.dart';
import '../common/section_card.dart';
import '../common/upload_feedback.dart';
import 'storage_page.dart';
import 'upload_section.dart';

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

class _DriveTab extends ConsumerStatefulWidget {
  const _DriveTab();

  @override
  ConsumerState<_DriveTab> createState() => _DriveTabState();
}

class _DriveTabState extends ConsumerState<_DriveTab> {
  String? _pickError;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DriveController get _drive => ref.read(driveControllerProvider.notifier);

  Future<void> _pickAndUpload() async {
    setState(() => _pickError = null);
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null) return;
      final paths = [
        for (final f in result.files)
          if (f.path != null) f.path!
      ];
      if (paths.isEmpty) return;
      ref.read(uploadQueueProvider.notifier).addFiles(paths,
          parentId: ref.read(driveControllerProvider).folderId);
    } catch (_) {
      setState(() => _pickError = 'Couldn\'t open the file picker. Try again.');
    }
  }

  Future<void> _download(DriveItem item) async {
    final dir = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Choose where to save');
    if (dir == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Downloads arrive once you\'re connected to Telegram — nothing was saved yet.'),
      ),
    );
  }

  void _navigateTo(int index) {
    _drive.navigateTo(index);
    _searchCtrl.clear();
  }

  Widget _breadcrumb(BuildContext context, DriveState drive) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Back',
          onPressed: () {
            _drive.up();
            _searchCtrl.clear();
          },
          icon: const Icon(Iconsax.arrow_left_2, size: 18),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                for (var i = 0; i < drive.stack.length; i++) ...[
                  if (i > 0)
                    Icon(Icons.chevron_right,
                        size: 15, color: scheme.onSurfaceVariant),
                  TextButton(
                    onPressed: () => _navigateTo(i),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      foregroundColor: i == drive.stack.length - 1
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: Text(drive.stack[i].name),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sortButton(BuildContext context, DriveState drive) {
    const labels = ['Name', 'Size', 'Modified'];
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<DriveSortField>(
      tooltip: 'Sort',
      onSelected: (f) => _drive.setSort(f),
      itemBuilder: (_) => [
        for (final f in DriveSortField.values)
          PopupMenuItem(
            value: f,
            height: 40,
            child: Row(
              children: [
                Icon(
                  f == drive.sortField
                      ? (drive.sortAsc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.sort,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(labels[f.index], style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.sort, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              labels[drive.sortField.index],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(BuildContext context, DriveItem item) {
    final scheme = Theme.of(context).colorScheme;
    return IconBadgeRow(
      icon: item.isFolder ? Iconsax.folder_2 : uploadFileIcon(item.name),
      title: item.name,
      subtitle: item.isFolder
          ? 'Folder'
          : '${formatBytes(item.size)} · ${formatDate(item.modified)}',
      trailing: item.isFolder
          ? Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant)
          : IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Download',
              onPressed: () => _download(item),
              icon: Icon(Iconsax.document_download,
                  size: 18, color: scheme.onSurfaceVariant),
            ),
      onTap: item.isFolder
          ? () {
              _drive.open(item.id);
              _searchCtrl.clear();
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final drive = ref.watch(driveControllerProvider);
    final tasks = ref.watch(uploadQueueProvider);
    final items = drive.visible;
    return _TabScaffold(
      title: 'My Drive',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _drive.setQuery,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search your drive',
                    prefixIcon:
                        Icon(Iconsax.search_normal_1, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.half),
              IconButton.filledTonal(
                tooltip: 'Upload files',
                onPressed: _pickAndUpload,
                icon: const Icon(Iconsax.document_upload, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.half),
          Row(
            children: [
              Expanded(
                child: drive.stack.length > 1 && !drive.searching
                    ? _breadcrumb(context, drive)
                    : const SizedBox.shrink(),
              ),
              _sortButton(context, drive),
            ],
          ),
          const SizedBox(height: AppSpace.half),
          Expanded(
            child: drive.loading
                ? const Align(
                    alignment: Alignment.topCenter, child: ShimmerTiles())
                : ListView(
                    padding: const EdgeInsets.only(bottom: AppSpace.section),
                    children: [
                      if (_pickError != null) ...[
                        InlineError(
                            message: _pickError!, onRetry: _pickAndUpload),
                        const SizedBox(height: AppSpace.base),
                      ],
                      if (tasks.isNotEmpty) ...[
                        const UploadSection(),
                        const SizedBox(height: AppSpace.base),
                      ],
                      if (items.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpace.section),
                          child: EmptyState(
                            title: drive.searching
                                ? 'No matches'
                                : (drive.stack.length > 1
                                    ? 'This folder is empty'
                                    : 'Your drive is empty'),
                            subtitle: drive.searching
                                ? 'Nothing in your drive matches "${drive.query.trim()}".'
                                : 'Upload a file to keep it in your Telegram cloud.',
                            action: drive.searching
                                ? null
                                : FilledButton.tonalIcon(
                                    onPressed: _pickAndUpload,
                                    icon: const Icon(Iconsax.document_upload,
                                        size: 18),
                                    label: const Text('Upload a file'),
                                  ),
                          ),
                        )
                      else
                        SectionCard(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.half),
                          child: Column(
                            children: [
                              for (final item in items) _itemRow(context, item)
                            ],
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
          SectionCard(
            icon: Iconsax.driver,
            title: 'Storage',
            padding: const EdgeInsets.only(bottom: AppSpace.half),
            child: IconBadgeRow(
              icon: Iconsax.folder_cloud,
              title: 'Storage & limits',
              subtitle:
                  'Up to 2 GB per file · how SannDrive keeps your account safe',
              trailing: Icon(Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const MobileStoragePage()),
              ),
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
