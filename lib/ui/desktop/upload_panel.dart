import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/models/drive_item.dart';
import '../../shared/models/upload_item.dart';
import '../../shared/services/upload/upload_queue.dart';
import '../common/upload_feedback.dart';
import 'type_style.dart';

class UploadPanel extends ConsumerStatefulWidget {
  const UploadPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<UploadPanel> createState() => _UploadPanelState();
}

class _UploadPanelState extends ConsumerState<UploadPanel> {
  bool _collapsed = false;
  String? _hovered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tasks = ref.watch(uploadQueueProvider);
    if (tasks.isEmpty) return const SizedBox.shrink();

    final total = tasks.length;
    final done = tasks.where((t) => t.status == UploadStatus.done).length;
    final pending = tasks.any((t) =>
        t.status == UploadStatus.queued ||
        t.status == UploadStatus.uploading ||
        t.status == UploadStatus.paused);
    final floodUntil =
        floodWaitUntilOf(tasks, DateTime.now().millisecondsSinceEpoch);

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
            value: overallUploadProgress(tasks),
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
                    pending ? 'Uploading $done of $total…' : 'Uploads complete',
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
                  onPressed: () {
                    ref.read(uploadQueueProvider.notifier).clearCompleted();
                    widget.onClose();
                  },
                  icon:
                      Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (floodUntil != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: FloodWaitBanner(untilEpochMs: floodUntil, dense: true),
            ),
          if (!_collapsed) ...[
            for (final t in tasks) _row(context, scheme, t),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ColorScheme scheme, UploadTask t) {
    final hovered = _hovered == t.id;
    final dimmed = t.status == UploadStatus.canceled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = t.id),
      onExit: (_) => setState(() {
        if (_hovered == t.id) _hovered = null;
      }),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Opacity(
          opacity: dimmed ? 0.5 : 1,
          child: Row(
            children: [
              TypeIconChip(item: _asDriveItem(t), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _meta(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: t.status == UploadStatus.failed
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 28, height: 28, child: _trailing(scheme, t, hovered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing(ColorScheme scheme, UploadTask t, bool hovered) {
    final queue = ref.read(uploadQueueProvider.notifier);
    switch (t.status) {
      case UploadStatus.done:
        return Icon(Iconsax.tick_circle, size: 22, color: scheme.primary);
      case UploadStatus.canceled:
        return Icon(Iconsax.close_circle,
            size: 22, color: scheme.onSurfaceVariant);
      case UploadStatus.failed:
        return _iconAction(
          hovered ? Iconsax.refresh : Iconsax.warning_2,
          hovered ? scheme.primary : scheme.error,
          hovered ? () => queue.retry(t.id) : null,
          hovered ? 'Retry' : null,
        );
      case UploadStatus.paused:
        return hovered
            ? _iconAction(Icons.close, scheme.onSurfaceVariant,
                () => queue.cancel(t.id), 'Cancel')
            : Icon(Iconsax.timer_1, size: 20, color: scheme.tertiary);
      case UploadStatus.queued:
      case UploadStatus.uploading:
        if (hovered) {
          return _iconAction(Icons.close, scheme.onSurfaceVariant,
              () => queue.cancel(t.id), 'Cancel');
        }
        return Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            value: t.status == UploadStatus.queued ? 0 : t.progress,
            strokeWidth: 2.5,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.primary,
          ),
        );
    }
  }

  Widget _iconAction(
      IconData icon, Color color, VoidCallback? onTap, String? tooltip) {
    final button = IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, size: 19, color: color),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  String _meta(UploadTask t) {
    final size = formatBytes(t.sizeBytes);
    switch (t.status) {
      case UploadStatus.uploading:
        return '${formatBytes(t.sentBytes)} of $size';
      case UploadStatus.paused:
        return 'Waiting for Telegram…';
      case UploadStatus.failed:
        return t.error ?? 'Upload failed';
      case UploadStatus.canceled:
        return 'Canceled';
      case UploadStatus.queued:
        return 'Queued · $size';
      case UploadStatus.done:
        return size;
    }
  }

  DriveItem _asDriveItem(UploadTask t) {
    final dot = t.name.lastIndexOf('.');
    return DriveItem(
      id: t.id,
      name: t.name,
      size: t.sizeBytes,
      modified: DateTime.now(),
      ext: dot >= 0 ? t.name.substring(dot + 1) : '',
    );
  }
}
