import 'package:equatable/equatable.dart';
import '../entities/user.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

enum MessageType { info, error }

class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    required this.message,
    required this.messageType,
  });

  const AuthState.loading()
    : this._(
        status: AuthStatus.loading,
        message: '',
        messageType: MessageType.info,
      );

  const AuthState.authenticated(User user)
    : this._(
        status: AuthStatus.authenticated,
        user: user,
        message: '',
        messageType: MessageType.info,
      );

  const AuthState.unauthenticated(String message, {MessageType? messageType})
    : this._(
        status: AuthStatus.unauthenticated,
        message: message,
        messageType: messageType ?? MessageType.info,
      );

  final AuthStatus status;
  final User? user;
  final String message;
  final MessageType messageType;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    MessageType? messageType,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
    );
  }

  @override
  List<Object?> get props => [status, user, message, messageType];
}
