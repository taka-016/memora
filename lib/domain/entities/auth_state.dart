import 'package:equatable/equatable.dart';
import 'user.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
  emailNotVerified,
}

class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.errorMessage});

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.error(String errorMessage)
    : this._(status: AuthStatus.error, errorMessage: errorMessage);

  const AuthState.emailNotVerified()
    : this._(status: AuthStatus.emailNotVerified);

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
