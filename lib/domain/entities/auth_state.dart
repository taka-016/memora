import 'package:equatable/equatable.dart';
import 'user.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error, success }

class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.message});

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.error(String message)
    : this._(status: AuthStatus.error, message: message);

  const AuthState.success(String message)
    : this._(status: AuthStatus.success, message: message);

  final AuthStatus status;
  final User? user;
  final String? message;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, User? user, String? message}) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, user, message];
}
