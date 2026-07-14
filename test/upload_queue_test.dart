import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanndrive/shared/models/upload_item.dart';
import 'package:sanndrive/shared/services/telegram/auth.dart';
import 'package:sanndrive/shared/services/telegram/tg_client.dart';
import 'package:sanndrive/shared/services/upload/upload_queue.dart';

class StubClient implements TgClient {
  StubClient({this.floodOnce = false, this.failOncePaths = const {}});

  final bool floodOnce;
  final Set<String> failOncePaths;

  final _watch = Stopwatch()..start();
  final startsMs = <int>[];
  final startPaths = <String>[];
  int concurrent = 0;
  int maxConcurrent = 0;
  bool _flooded = false;
  final _failed = <String>{};

  @override
  Stream<double> upload(String path, {String? caption}) async* {
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    startsMs.add(_watch.elapsedMilliseconds);
    startPaths.add(path);
    try {
      for (var i = 1; i <= 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (floodOnce && !_flooded && i == 2) {
          _flooded = true;
          throw const FloodWaitException(1);
        }
        if (i == 2 && failOncePaths.contains(path) && _failed.add(path)) {
          throw StateError('boom');
        }
        yield i / 4;
      }
    } finally {
      concurrent--;
    }
  }

  @override
  Stream<AuthStep> get authSteps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setPhone(String phone) async {}

  @override
  Future<void> checkCode(String code) async {}

  @override
  Future<void> checkPassword(String password) async {}

  @override
  Future<void> logOut() async {}

  @override
  void dispose() {}
}

Future<void> waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  var waited = Duration.zero;
  const step = Duration(milliseconds: 10);
  while (!condition()) {
    if (waited >= timeout) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(step);
    waited += step;
  }
}

void main() {
  test('runs uploads serially in order, never in parallel', () async {
    final client = StubClient();
    final queue = UploadQueue(
      client,
      minStartGap: const Duration(milliseconds: 200),
      sizeOf: (_) => 1000,
    );
    queue.addFiles(['a.bin', 'b.bin', 'c.bin']);

    await waitUntil(
        () => queue.tasks.every((t) => t.status == UploadStatus.done));

    expect(client.maxConcurrent, 1);
    expect(client.startPaths, ['a.bin', 'b.bin', 'c.bin']);
    queue.dispose();
  });

  test('respects the minimum gap between upload starts', () async {
    final client = StubClient();
    final queue = UploadQueue(
      client,
      minStartGap: const Duration(milliseconds: 200),
      sizeOf: (_) => 1000,
    );
    queue.addFiles(['a.bin', 'b.bin', 'c.bin']);

    await waitUntil(
        () => queue.tasks.every((t) => t.status == UploadStatus.done));

    expect(client.startsMs, hasLength(3));
    for (var i = 1; i < client.startsMs.length; i++) {
      expect(client.startsMs[i] - client.startsMs[i - 1],
          greaterThanOrEqualTo(150));
    }
    queue.dispose();
  });

  test('FLOOD_WAIT pauses the task, cools down, then resumes and finishes',
      () async {
    final client = StubClient(floodOnce: true);
    final queue = UploadQueue(
      client,
      minStartGap: const Duration(milliseconds: 50),
      sizeOf: (_) => 1000,
    );
    queue.addFiles(['a.bin']);

    await waitUntil(
        () => queue.tasks.single.status == UploadStatus.paused);
    expect(queue.tasks.single.floodWaitUntilEpochMs, isNotNull);
    expect(queue.isCoolingDown, isTrue);
    expect(queue.cooldownRemaining, greaterThan(Duration.zero));

    await waitUntil(() => queue.tasks.single.status == UploadStatus.done);
    expect(client.startsMs, hasLength(2));
    expect(client.startsMs[1] - client.startsMs[0], greaterThanOrEqualTo(900));
    expect(queue.tasks.single.floodWaitUntilEpochMs, isNull);
    queue.dispose();
  });

  test('failures are marked with a friendly error and retry works', () async {
    final client = StubClient(failOncePaths: {'bad.bin'});
    final queue = UploadQueue(
      client,
      minStartGap: const Duration(milliseconds: 50),
      sizeOf: (_) => 1000,
    );
    queue.addFiles(['bad.bin']);

    await waitUntil(
        () => queue.tasks.single.status == UploadStatus.failed);
    expect(queue.tasks.single.error, isNotNull);
    expect(queue.tasks.single.error, isNot(contains('boom')));

    queue.retry(queue.tasks.single.id);
    await waitUntil(() => queue.tasks.single.status == UploadStatus.done);
    expect(client.startsMs, hasLength(2));
    queue.dispose();
  });

  test('cancel removes queued work and clearCompleted prunes the list',
      () async {
    final client = StubClient();
    final queue = UploadQueue(
      client,
      minStartGap: const Duration(milliseconds: 50),
      sizeOf: (_) => 1000,
    );
    queue.addFiles(['a.bin', 'b.bin']);
    final second = queue.tasks[1].id;
    queue.cancel(second);

    await waitUntil(
        () => queue.tasks.first.status == UploadStatus.done);
    expect(queue.tasks[1].status, UploadStatus.canceled);
    expect(client.startPaths, ['a.bin']);

    queue.clearCompleted();
    expect(queue.tasks, isEmpty);
    queue.dispose();
  });
}
