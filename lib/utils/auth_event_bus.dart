import 'dart:async';

class AuthEvent {
  final String type;
  final String? message;

  const AuthEvent._(this.type, this.message);

  const AuthEvent.invalidToken([String? message])
    : this._('invalid_token', message);
}

class AuthEventBus {
  static final AuthEventBus _instance = AuthEventBus._internal();

  factory AuthEventBus() => _instance;

  AuthEventBus._internal();

  final StreamController<AuthEvent> _controller =
      StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void reportInvalidToken([String? message]) {
    if (_controller.isClosed) return;
    _controller.add(AuthEvent.invalidToken(message));
  }
}
