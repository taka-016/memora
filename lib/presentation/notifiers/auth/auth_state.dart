import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/account/user_dto.dart';

const memberSelectionRequiredMessage = 'member_selection_required';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
  initializationFailed,
}

enum MessageType { info, error }

class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this.member,
    required this.message,
    required this.messageType,
  });

  const AuthState.loading()
    : this._(
        status: AuthStatus.loading,
        message: '',
        messageType: MessageType.info,
      );

  const AuthState.authenticated(UserDto user, {MemberDto? member})
    : this._(
        status: AuthStatus.authenticated,
        user: user,
        member: member,
        message: '',
        messageType: MessageType.info,
      );

  const AuthState.unauthenticated(String message, {MessageType? messageType})
    : this._(
        status: AuthStatus.unauthenticated,
        message: message,
        messageType: messageType ?? MessageType.info,
      );

  const AuthState.initializationFailed(String message)
    : this._(
        status: AuthStatus.initializationFailed,
        message: message,
        messageType: MessageType.error,
      );

  final AuthStatus status;
  final UserDto? user;
  final MemberDto? member;
  final String message;
  final MessageType messageType;

  bool get isLoading => status == AuthStatus.loading;

  bool get hasInitializationError => status == AuthStatus.initializationFailed;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isInfoMessage => messageType == MessageType.info;

  bool get requiresMemberSelection => message == memberSelectionRequiredMessage;

  String? get authenticatedLoginId => user?.loginId;

  AuthState copyWith({
    AuthStatus? status,
    UserDto? user,
    String? message,
    MessageType? messageType,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      member: (status ?? this.status) == AuthStatus.authenticated &&
              (user ?? this.user)?.id == this.user?.id ? member : null,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
    );
  }

  @override
  List<Object?> get props => [status, user, member, message, messageType];
}
