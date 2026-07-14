import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/drive_controller.dart';
import '../../models/upload_item.dart';
import '../telegram/tg_client.dart';

final uploadQueueProvider =
    StateNotifierProvider<UploadQueue, List<UploadTask>>((ref) {
  return UploadQueue(
    ref.watch(tgClientProvider),
    onCompleted: (task) =>
        ref.read(driveControllerProvider.notifier).addUploaded(
              name: task.name,
              sizeBytes: task.sizeBytes,
              parentId: task.parentId,
            ),
  );
});

class _Canceled {
  const _Canceled();
}

int _fileSize(String path) {
  try {
    return File(path).lengthSync();
  } catch (_) {
    return 0;
  }
}

class UploadQueue extends StateNotifier<List<UploadTask>> {
  UploadQueue(
    this._client, {
    this.minStartGap = const Duration(milliseconds: 1200),
    int Function(String path)? sizeOf,
    void Function(UploadTask task)? onCompleted,
  })  : _sizeOf = sizeOf ?? _fileSize,
        _onCompleted = onCompleted,
        super(const []);

  final TgClient _client;
  final Duration minStartGap;
  final int Function(String path) _sizeOf;
  final void Function(UploadTask task)? _onCompleted;

  int _seq = 0;
  bool _pumping = false;
  DateTime? _lastStart;
  DateTime? _cooldownUntil;
  String? _activeId;
  StreamSubscription<double>? _activeSub;
  Completer<Object?>? _activeDone;

  List<UploadTask> get tasks => state;

  int get activeCount =>
      state.where((t) => t.status == UploadStatus.uploading).length;

  bool get isCoolingDown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  Duration get cooldownRemaining {
    final until = _cooldownUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void addFiles(List<String> paths, {String? parentId}) {
    if (paths.isEmpty) return;
    state = [
      ...state,
      for (final p in paths)
        UploadTask(
          id: 'up-${++_seq}',
          name: p.split(RegExp(r'[\\/]')).last,
          path: p,
          sizeBytes: _sizeOf(p),
          parentId: parentId,
        ),
    ];
    _pump();
  }

  void cancel(String id) {
    if (id == _activeId) {
      final done = _activeDone;
      if (done != null && !done.isCompleted) done.complete(const _Canceled());
      return;
    }
    _update(id, (t) {
      if (t.status == UploadStatus.queued || t.status == UploadStatus.paused) {
        return t.copyWith(status: UploadStatus.canceled, clearFloodWait: true);
      }
      return t;
    });
  }

  void retry(String id) {
    _update(id, (t) {
      if (t.status == UploadStatus.failed || t.status == UploadStatus.canceled) {
        return t.copyWith(
            status: UploadStatus.queued, sentBytes: 0, clearError: true);
      }
      return t;
    });
    _pump();
  }

  void clearCompleted() {
    state = [
      for (final t in state)
        if (t.status != UploadStatus.done && t.status != UploadStatus.canceled) t
    ];
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (mounted) {
        final cooldown = _cooldownUntil;
        if (cooldown != null) {
          final wait = cooldown.difference(DateTime.now());
          if (wait > Duration.zero) {
            await Future<void>.delayed(wait);
          }
          if (!mounted) return;
          _cooldownUntil = null;
          state = [
            for (final t in state)
              t.status == UploadStatus.paused
                  ? t.copyWith(
                      status: UploadStatus.queued, clearFloodWait: true)
                  : t
          ];
        }
        UploadTask? next;
        for (final t in state) {
          if (t.status == UploadStatus.queued) {
            next = t;
            break;
          }
        }
        if (next == null) break;
        final last = _lastStart;
        if (last != null) {
          final wait = minStartGap - DateTime.now().difference(last);
          if (wait > Duration.zero) {
            await Future<void>.delayed(wait);
          }
          if (!mounted) return;
        }
        UploadTask? current;
        for (final t in state) {
          if (t.id == next.id) {
            current = t;
            break;
          }
        }
        if (current == null || current.status != UploadStatus.queued) continue;
        await _runTask(current);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _runTask(UploadTask task) async {
    _lastStart = DateTime.now();
    _activeId = task.id;
    _update(task.id, (t) => t.copyWith(status: UploadStatus.uploading));
    final done = Completer<Object?>();
    _activeDone = done;
    _activeSub = _client.upload(task.path).listen(
      (p) {
        final v = p < 0 ? 0.0 : (p > 1 ? 1.0 : p);
        _update(
            task.id, (t) => t.copyWith(sentBytes: (v * t.sizeBytes).round()));
      },
      onError: (Object e) {
        if (!done.isCompleted) done.complete(e);
      },
      onDone: () {
        if (!done.isCompleted) done.complete(null);
      },
      cancelOnError: true,
    );
    final result = await done.future;
    await _activeSub?.cancel();
    _activeSub = null;
    _activeDone = null;
    _activeId = null;
    if (!mounted) return;
    if (result == null) {
      _update(task.id,
          (t) => t.copyWith(status: UploadStatus.done, sentBytes: t.sizeBytes));
      for (final t in state) {
        if (t.id == task.id && t.status == UploadStatus.done) {
          _onCompleted?.call(t);
          break;
        }
      }
    } else if (result is _Canceled) {
      _update(task.id, (t) => t.copyWith(status: UploadStatus.canceled));
    } else if (result is FloodWaitException) {
      final until = DateTime.now().add(Duration(seconds: result.seconds));
      _cooldownUntil = until;
      _update(
        task.id,
        (t) => t.copyWith(
          status: UploadStatus.paused,
          floodWaitUntilEpochMs: until.millisecondsSinceEpoch,
        ),
      );
    } else {
      _update(
        task.id,
        (t) => t.copyWith(
          status: UploadStatus.failed,
          error: 'Couldn\'t upload this file. Check your connection and try again.',
        ),
      );
    }
  }

  void _update(String id, UploadTask Function(UploadTask) fn) {
    if (!mounted) return;
    state = [for (final t in state) t.id == id ? fn(t) : t];
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    final done = _activeDone;
    if (done != null && !done.isCompleted) done.complete(const _Canceled());
    super.dispose();
  }
}
