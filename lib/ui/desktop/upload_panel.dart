import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/models/drive_item.dart';
import 'type_style.dart';

class UploadPanel extends StatefulWidget {
  const UploadPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<UploadPanel> createState() => _UploadPanelState();
}

class _UploadPanelState extends State<UploadPanel> {
  bool _collapsed = false;

  static final _entries = [
    (
      item: DriveItem(
          id: 'u1',
          name: 'Product hero.png',
          size: 8912896,
          modified: DateTime(2026, 7, 13),
          ext: 'png'),
      progress: 1.0
    ),
    (
      item: DriveItem(
          id: 'u2',
          name: 'Aurora timelapse.mp4',
          size: 734003200,
          modified: DateTime(2026, 7, 12),
          ext: 'mp4'),
      progress: 0.62
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 384,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: 0.81,
            minHeight: 3,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Uploading…',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: Icon(
                    _collapsed ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon:
                      Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!_collapsed) ...[
            for (final e in _entries)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: [
                    TypeIconChip(item: e.item, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5, color: scheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatBytes(e.item.size),
                            style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: e.progress >= 1
                          ? Icon(Iconsax.tick_circle,
                              size: 22, color: scheme.primary)
                          : CircularProgressIndicator(
                              value: e.progress,
                              strokeWidth: 2.5,
                              backgroundColor: scheme.surfaceContainerHighest,
                              color: scheme.primary,
                            ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
