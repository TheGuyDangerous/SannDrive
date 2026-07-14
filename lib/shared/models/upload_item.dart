enum UploadStatus { queued, uploading, paused, done, failed, canceled }

int? floodWaitUntilOf(List<UploadTask> tasks, int nowEpochMs) {
  int? until;
  for (final t in tasks) {
    final ms = t.floodWaitUntilEpochMs;
    if (t.status == UploadStatus.paused && ms != null && ms > nowEpochMs) {
      if (until == null || ms > until) until = ms;
    }
  }
  return until;
}

double overallUploadProgress(List<UploadTask> tasks) {
  var total = 0;
  var sent = 0;
  for (final t in tasks) {
    if (t.status == UploadStatus.canceled) continue;
    total += t.sizeBytes;
    sent += t.status == UploadStatus.done ? t.sizeBytes : t.sentBytes;
  }
  if (total <= 0) return 0;
  final p = sent / total;
  return p < 0 ? 0 : (p > 1 ? 1 : p);
}

class UploadTask {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final int sentBytes;
  final UploadStatus status;
  final String? error;
  final int? floodWaitUntilEpochMs;
  final String? parentId;

  const UploadTask({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.sentBytes = 0,
    this.status = UploadStatus.queued,
    this.error,
    this.floodWaitUntilEpochMs,
    this.parentId,
  });

  double get progress {
    if (status == UploadStatus.done) return 1;
    if (sizeBytes <= 0) return 0;
    final p = sentBytes / sizeBytes;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  bool get isFinished =>
      status == UploadStatus.done ||
      status == UploadStatus.failed ||
      status == UploadStatus.canceled;

  UploadTask copyWith({
    int? sentBytes,
    UploadStatus? status,
    String? error,
    bool clearError = false,
    int? floodWaitUntilEpochMs,
    bool clearFloodWait = false,
  }) {
    return UploadTask(
      id: id,
      name: name,
      path: path,
      sizeBytes: sizeBytes,
      sentBytes: sentBytes ?? this.sentBytes,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      floodWaitUntilEpochMs: clearFloodWait
          ? null
          : (floodWaitUntilEpochMs ?? this.floodWaitUntilEpochMs),
      parentId: parentId,
    );
  }
}
