import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/controllers/auth_controller.dart';
import '../../shared/models/drive_item.dart';
import '../../theme/desktop_theme.dart';
import 'drop_overlay.dart';
import 'storage_view.dart';
import 'type_style.dart';
import 'upload_panel.dart';

class DesktopHome extends ConsumerStatefulWidget {
  const DesktopHome({super.key});

  @override
  ConsumerState<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends ConsumerState<DesktopHome> {
  int _section = 0;
  bool _dark = true;
  bool _grid = false;
  int _sortField = 0;
  bool _sortAsc = true;
  List<String> _path = const [];
  final Set<String> _selected = {};
  int? _anchor;
  bool _dragging = false;
  bool _uploadsVisible = true;
  String? _lastTapId;
  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);
  final _searchFocus = FocusNode();
  final _viewFocus = FocusNode();
  final _searchCtrl = TextEditingController();

  static const _sections = [
    (icon: Iconsax.folder_2, label: 'My Drive'),
    (icon: Iconsax.clock, label: 'Recent'),
    (icon: Iconsax.people, label: 'Shared'),
    (icon: Iconsax.driver, label: 'Storage'),
  ];

  static const _sortLabels = ['Name', 'Size', 'Modified'];

  @override
  void dispose() {
    _searchFocus.dispose();
    _viewFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DriveItem> get _visible {
    final src = _section == 1 ? DriveStub.recent : DriveStub.itemsIn(_path);
    final items = [...src];
    items.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      final c = switch (_sortField) {
        1 => a.size.compareTo(b.size),
        2 => a.modified.compareTo(b.modified),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return _sortAsc ? c : -c;
    });
    return items;
  }

  void _select(int index, DriveItem item) {
    final keys = HardwareKeyboard.instance;
    final ctrl = keys.isControlPressed || keys.isMetaPressed;
    final shift = keys.isShiftPressed;
    final items = _visible;
    setState(() {
      if (shift && _anchor != null && _anchor! < items.length) {
        final lo = _anchor! < index ? _anchor! : index;
        final hi = _anchor! < index ? index : _anchor!;
        _selected
          ..clear()
          ..addAll([for (var i = lo; i <= hi; i++) items[i].id]);
      } else if (ctrl) {
        if (!_selected.remove(item.id)) _selected.add(item.id);
        _anchor = index;
      } else {
        _selected
          ..clear()
          ..add(item.id);
        _anchor = index;
      }
    });
  }

  void _tapItem(int index, DriveItem item) {
    _viewFocus.requestFocus();
    final keys = HardwareKeyboard.instance;
    final plain = !keys.isControlPressed &&
        !keys.isMetaPressed &&
        !keys.isShiftPressed;
    final now = DateTime.now();
    final isDouble = plain &&
        _lastTapId == item.id &&
        now.difference(_lastTapAt).inMilliseconds < 400;
    _lastTapId = item.id;
    _lastTapAt = now;
    if (isDouble) {
      _open(item);
      return;
    }
    _select(index, item);
  }

  void _open(DriveItem item) {
    if (item.isFolder && _section == 0) {
      setState(() {
        _path = [..._path, item.name];
        _selected.clear();
        _anchor = null;
      });
    }
  }

  void _goUp() {
    if (_path.isEmpty) return;
    setState(() {
      _path = _path.sublist(0, _path.length - 1);
      _selected.clear();
      _anchor = null;
    });
  }

  void _selectAll() => setState(() {
        _selected
          ..clear()
          ..addAll(_visible.map((e) => e.id));
      });

  void _clearSelection() => setState(() {
        _selected.clear();
        _anchor = null;
      });

  ColorScheme get _scheme =>
      (_dark ? DesktopTheme.dark : DesktopTheme.light).colorScheme;

  void _secondaryTap(Offset pos, int index, DriveItem item) {
    _viewFocus.requestFocus();
    if (!_selected.contains(item.id)) {
      setState(() {
        _selected
          ..clear()
          ..add(item.id);
        _anchor = index;
      });
    }
    _contextMenu(pos);
  }

  Future<void> _contextMenu(Offset pos) async {
    final scheme = _scheme;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
          pos & const Size(1, 1), Offset.zero & overlay.size),
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      items: [
        _menuItem('open', Iconsax.export_3, 'Open', scheme),
        _menuItem('share', Iconsax.share, 'Share', scheme),
        _menuItem('link', Iconsax.link_2, 'Copy Link', scheme),
        _menuItem('rename', Iconsax.edit_2, 'Rename', scheme),
        _menuItem('move', Iconsax.folder_open, 'Move', scheme),
        _menuItem('download', Iconsax.document_download, 'Download', scheme),
        _menuItem('delete', Iconsax.trash, 'Delete', scheme),
      ],
    );
    if (action == 'open' && _selected.length == 1) {
      for (final it in _visible) {
        if (it.id == _selected.first) {
          _open(it);
          break;
        }
      }
    }
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, ColorScheme scheme) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.rubik(
                  fontSize: 13.5, color: scheme.onSurface)),
        ],
      ),
    );
  }

  MenuStyle _menuStyle(ColorScheme scheme) => MenuStyle(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      );

  MenuItemButton _menuButton(ColorScheme scheme, IconData icon, String label,
      {VoidCallback? onPressed}) {
    return MenuItemButton(
      onPressed: onPressed ?? () {},
      leadingIcon: Icon(icon, size: 16, color: scheme.onSurfaceVariant),
      style: MenuItemButton.styleFrom(
        foregroundColor: scheme.onSurface,
        textStyle: GoogleFonts.rubik(fontSize: 13.5),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? DesktopTheme.dark : DesktopTheme.light,
      child: Builder(builder: (context) => _shell(context)),
    );
  }

  Widget _shell(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              _searchFocus.requestFocus(),
        },
        child: DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (detail) {
            setState(() => _dragging = false);
            for (final f in detail.files) {
              debugPrint('drop: ${f.path}');
            }
          },
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rail(context),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _topBar(context),
                        if (_section == 0) _breadcrumb(context),
                        if (_section <= 1) _toolbar(context),
                        Expanded(child: _body(context)),
                      ],
                    ),
                  ),
                ],
              ),
              if (_uploadsVisible)
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: UploadPanel(
                      onClose: () => setState(() => _uploadsVisible = false)),
                ),
              if (_dragging) const Positioned.fill(child: DropOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          const SizedBox(height: 16),
          for (var i = 0; i < _sections.length; i++)
            _RailItem(
              icon: _sections[i].icon,
              label: _sections[i].label,
              active: _section == i,
              onTap: () => setState(() {
                _section = i;
                _selected.clear();
                _anchor = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.cloud, size: 19, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'SannDrive',
              style: text.headlineSmall
                  ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    style: text.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search… (Ctrl+K)',
                      prefixIcon: Icon(Iconsax.search_normal_1,
                          size: 18, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: _dark ? 'Light mode' : 'Dark mode',
              onPressed: () => setState(() => _dark = !_dark),
              icon: Icon(_dark ? Iconsax.sun_1 : Iconsax.moon,
                  size: 20, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: '',
              offset: const Offset(0, 44),
              color: scheme.surfaceContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              itemBuilder: (_) => [
                _menuItem('settings', Iconsax.setting_2, 'Settings', scheme),
                _menuItem('signout', Iconsax.logout, 'Sign out', scheme),
              ],
              onSelected: (v) {
                if (v == 'signout') {
                  ref.read(authControllerProvider.notifier).logOut();
                }
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breadcrumb(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segs = ['My Drive', ..._path];
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Up',
              visualDensity: VisualDensity.compact,
              onPressed: _path.isEmpty ? null : _goUp,
              icon: const Icon(Iconsax.arrow_up_2, size: 18),
            ),
            const SizedBox(width: 4),
            for (var i = 0; i < segs.length; i++) ...[
              if (i > 0)
                Icon(Icons.chevron_right,
                    size: 16, color: scheme.onSurfaceVariant),
              TextButton(
                onPressed: () => setState(() {
                  _path = _path.sublist(0, i);
                  _selected.clear();
                  _anchor = null;
                }),
                style: TextButton.styleFrom(
                  backgroundColor: i == segs.length - 1
                      ? scheme.surfaceContainerHigh
                      : Colors.transparent,
                  foregroundColor: i == segs.length - 1
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 32),
                  textStyle: GoogleFonts.rubik(
                      fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                child: Text(segs[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          if (_selected.isNotEmpty) ...[
            IconButton(
              tooltip: 'Clear selection',
              visualDensity: VisualDensity.compact,
              onPressed: _clearSelection,
              icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Text(
              '${_selected.length} selected',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          MenuAnchor(
            style: _menuStyle(scheme),
            builder: (context, controller, _) => FilledButton.tonalIcon(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const Icon(Iconsax.add, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            menuChildren: [
              _menuButton(scheme, Iconsax.document_upload, 'Upload files'),
              _menuButton(scheme, Iconsax.folder_open, 'Upload folder'),
              _menuButton(scheme, Iconsax.folder_add, 'New folder'),
            ],
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: scheme.outlineVariant),
              selectedBackgroundColor: scheme.secondaryContainer,
              selectedForegroundColor: scheme.onSecondaryContainer,
              foregroundColor: scheme.onSurfaceVariant,
            ),
            segments: const [
              ButtonSegment(
                  value: false, icon: Icon(Iconsax.row_vertical, size: 16)),
              ButtonSegment(
                  value: true, icon: Icon(Iconsax.element_3, size: 16)),
            ],
            selected: {_grid},
            onSelectionChanged: (s) => setState(() => _grid = s.first),
          ),
          const SizedBox(width: 8),
          MenuAnchor(
            style: _menuStyle(scheme),
            builder: (context, controller, _) => OutlinedButton.icon(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const Icon(Iconsax.sort, size: 16),
              label: Text(_sortLabels[_sortField]),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.onSurfaceVariant,
                side: BorderSide(color: scheme.outlineVariant),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: GoogleFonts.rubik(fontSize: 13),
              ),
            ),
            menuChildren: [
              for (var i = 0; i < _sortLabels.length; i++)
                _menuButton(
                  scheme,
                  i == _sortField
                      ? (_sortAsc ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.sort,
                  _sortLabels[i],
                  onPressed: () => setState(() {
                    if (_sortField == i) {
                      _sortAsc = !_sortAsc;
                    } else {
                      _sortField = i;
                      _sortAsc = true;
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_section) {
      case 3:
        return const StorageView();
      case 2:
        return _emptyShared(context);
      default:
        return _fileArea(context);
    }
  }

  Widget _emptyShared(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child:
                Icon(Iconsax.people, size: 30, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('Nothing shared yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            'Files shared with you will appear here.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _fileArea(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = _visible;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            _selectAll,
        const SingleActivator(LogicalKeyboardKey.escape): _clearSelection,
      },
      child: Focus(
        focusNode: _viewFocus,
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _viewFocus.requestFocus();
            _clearSelection();
          },
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'This folder is empty',
                    style:
                        TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                )
              : _grid
                  ? _FileGrid(
                      items: items,
                      selected: _selected,
                      onTap: _tapItem,
                      onSecondary: _secondaryTap,
                    )
                  : _FileList(
                      items: items,
                      selected: _selected,
                      onTap: _tapItem,
                      onSecondary: _secondaryTap,
                    ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
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
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: active ? scheme.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: active
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.items,
    required this.selected,
    required this.onTap,
    required this.onSecondary,
  });

  final List<DriveItem> items;
  final Set<String> selected;
  final void Function(int, DriveItem) onTap;
  final void Function(Offset, int, DriveItem) onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      itemCount: items.length,
      itemExtent: 56,
      itemBuilder: (context, i) {
        final item = items[i];
        final sel = selected.contains(item.id);
        final metaStyle = TextStyle(
          fontSize: 13,
          color: sel
              ? scheme.onSecondaryContainer.withOpacity(0.8)
              : scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: GestureDetector(
            onSecondaryTapDown: (d) => onSecondary(d.globalPosition, i, item),
            child: Material(
              color: sel ? scheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                hoverColor: scheme.onSurface.withOpacity(0.05),
                onTap: () => onTap(i, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      TypeIconChip(item: item, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: sel
                                ? scheme.onSecondaryContainer
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          item.isFolder ? '—' : formatBytes(item.size),
                          style: metaStyle,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text(formatDate(item.modified), style: metaStyle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FileGrid extends StatelessWidget {
  const _FileGrid({
    required this.items,
    required this.selected,
    required this.onTap,
    required this.onSecondary,
  });

  final List<DriveItem> items;
  final Set<String> selected;
  final void Function(int, DriveItem) onTap;
  final void Function(Offset, int, DriveItem) onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 176,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final sel = selected.contains(item.id);
        return GestureDetector(
          onSecondaryTapDown: (d) => onSecondary(d.globalPosition, i, item),
          child: Material(
            color: sel ? scheme.secondaryContainer : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              hoverColor: scheme.onSurface.withOpacity(0.05),
              onTap: () => onTap(i, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: sel
                              ? scheme.surfaceContainerHigh.withOpacity(0.6)
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: TypeIconChip(item: item, size: 44)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: sel
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.isFolder
                          ? 'Folder'
                          : '${formatBytes(item.size)} · ${formatDate(item.modified)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: sel
                            ? scheme.onSecondaryContainer.withOpacity(0.8)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
