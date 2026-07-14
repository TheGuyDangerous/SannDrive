import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/models/upload_item.dart';
import '../../shared/services/upload/upload_queue.dart';
import '../../theme/app_theme.dart';
import '../common/section_card.dart';
import '../common/upload_feedback.dart';

IconData uploadFileIcon(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  switch (ext) {
    case 'mp4':
    case 'mkv':
    case 'mov':
    case 'avi':
    case 'webm':
      return Iconsax.video;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'm4a':
    case 'ogg':
      return Iconsax.music;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
    case 'svg':
      return Iconsax.gallery;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Iconsax.archive_1;
    case 'pdf':
    case 'doc':
    case 'docx':
    case 'txt':
    case 'md':
    case 'xls':
    case 'xlsx':
      return Iconsax.document_text;
    default:
      return Iconsax.document;
  }
}

String uploadFormatBytes(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  return u == 0 ? '$bytes B' : '${v.toStringAsFixed(1)} ${units[u]}';
}

class UploadSection extends ConsumerWidget {
  const UploadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(uploadQueueProvider);
    if (tasks.isEmpty) return const SizedBox.shrink();
    final queue = ref.read(uploadQueueProvider.notifier);
    final floodUntil =
        floodWaitUntilOf(tasks, DateTime.now().millisecondsSinceEpoch);
    final hasFinished = tasks.any((t) =>
        t.status == UploadStatus.done || t.status == UploadStatus.canceled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (floodUntil != null) ...[
          FloodWaitBanner(untilEpochMs: floodUntil),
          const SizedBox(height: AppSpace.base),
        ],
        SectionCard(
          icon: Iconsax.document_upload,
          title: 'Uploads',
          padding: const EdgeInsets.only(bottom: AppSpace.half),
          child: Column(
            children: [for (final t in tasks) _UploadRow(task: t, queue: queue)],
          ),
        ),
        if (hasFinished) ...[
          const SizedBox(height: AppSpace.half),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: queue.clearCompleted,
              child: const Text('Clear completed'),
            ),
          ),
        ],
      ],
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.task, required this.queue});

  final UploadTask task;
  final UploadQueue queue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dimmed = task.status == UploadStatus.canceled;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.base, vertical: 10),
      child: Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: Row(
          children: [
            IconBadge(icon: uploadFileIcon(task.name)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _meta(),
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: task.status == UploadStatus.failed
                          ? scheme.error
                          : scheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  if (task.status == UploadStatus.uploading) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 4,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _trailing(scheme),
          ],
        ),
      ),
    );
  }

  Widget _trailing(ColorScheme scheme) {
    switch (task.status) {
      case UploadStatus.done:
        return const Icon(Iconsax.tick_circle, size: 22, color: AppColors.brand);
      case UploadStatus.canceled:
        return Icon(Iconsax.close_circle,
            size: 22, color: scheme.onSurface.withOpacity(0.4));
      case UploadStatus.failed:
        return TextButton(
          onPressed: () => queue.retry(task.id),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: AppColors.brand,
            textStyle: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          child: const Text('Retry'),
        );
      case UploadStatus.paused:
        return Icon(Iconsax.timer_1, size: 20, color: scheme.tertiary);
      case UploadStatus.queued:
      case UploadStatus.uploading:
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Cancel',
          onPressed: () => queue.cancel(task.id),
          icon: Icon(Iconsax.close_circle,
              size: 20, color: scheme.onSurface.withOpacity(0.55)),
        );
    }
  }

  String _meta() {
    final size = uploadFormatBytes(task.sizeBytes);
    switch (task.status) {
      case UploadStatus.uploading:
        return '${uploadFormatBytes(task.sentBytes)} of $size';
      case UploadStatus.paused:
        return 'Waiting for Telegram…';
      case UploadStatus.failed:
        return task.error ?? 'Upload failed';
      case UploadStatus.canceled:
        return 'Canceled';
      case UploadStatus.queued:
        return 'Queued · $size';
      case UploadStatus.done:
        return 'Uploaded · $size';
    }
  }
}
