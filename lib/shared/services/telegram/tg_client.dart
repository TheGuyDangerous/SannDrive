import 'dart:async';

import 'auth.dart';

abstract class TgClient {
  Stream<AuthStep> get authSteps;
  Future<void> initialize();
  Future<void> setPhone(String phone);
  Future<void> checkCode(String code);
  Future<void> checkPassword(String password);
  Future<void> logOut();
  void dispose();
}

class FakeTgClient implements TgClient {
  final _controller = StreamController<AuthStep>.broadcast();

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
  Future<void> logOut() async {
    _controller.add(AuthStep.loggingOut);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _controller.add(AuthStep.waitPhone);
  }

  @override
  void dispose() => _controller.close();
}
