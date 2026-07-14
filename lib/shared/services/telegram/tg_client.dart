import 'dart:async';
import 'dart:io';

import 'auth.dart';

class FloodWaitException implements Exception {
  final int seconds;
  const FloodWaitException(this.seconds);

  @override
  String toString() => 'FLOOD_WAIT ($seconds s)';
}

abstract class TgClient {
  Stream<AuthStep> get authSteps;
  Future<void> initialize();
  Future<void> setPhone(String phone);
  Future<void> checkCode(String code);
  Future<void> checkPassword(String password);
  Stream<double> upload(String path, {String? caption});
  Future<void> logOut();
  void dispose();
}

class FakeTgClient implements TgClient {
  final _controller = StreamController<AuthStep>.broadcast();
  int _uploads = 0;

  @override
  Stream<AuthStep> get authSteps => _controller.stream;

  @override
  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _controller.add(AuthStep.waitPhone);
  }

  @override
  Future<void> setPhone(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _controller.add(AuthStep.waitCode);
  }

  @override
  Future<void> checkCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _controller.add(code.trim() == '22222' ? AuthStep.waitPassword : AuthStep.ready);
  }

  @override
  Future<void> checkPassword(String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _controller.add(AuthStep.ready);
  }

  @override
  Stream<double> upload(String path, {String? caption}) async* {
    final n = ++_uploads;
    var size = 0;
    try {
      size = File(path).lengthSync();
    } catch (_) {}
    final totalMs = (2000 + size ~/ 700000).clamp(2000, 4000);
    const steps = 30;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(Duration(milliseconds: totalMs ~/ steps));
      if (n % 4 == 0 && i == steps ~/ 2) {
        throw const FloodWaitException(15);
      }
      yield i / steps;
    }
  }

  @override
  Future<void> logOut() async {
    _controller.add(AuthStep.loggingOut);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _controller.add(AuthStep.waitPhone);
  }

  @override
  void dispose() => _controller.close();
}
