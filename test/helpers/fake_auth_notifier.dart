import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';

/// テスト用のFakeAuthNotifier
///
/// StateNotifierとして正常に動作するテスト専用のAuthNotifier実装
class FakeAuthNotifier extends AuthNotifier {
  bool _signupCalled = false;
  bool _loginCalled = false;

  bool get signupCalled => _signupCalled;
  bool get loginCalled => _loginCalled;

  FakeAuthNotifier(AuthState initialState)
    : super(
        authService: _FakeAuthService(),
        checkMemberExistsUseCase: _FakeCheckMemberExistsUseCase(),
        createMemberFromUserUseCase: _FakeCreateMemberFromUserUseCase(),
        acceptInvitationUseCase: _FakeAcceptInvitationUseCase(),
      ) {
    state = initialState;
  }

  factory FakeAuthNotifier.authenticated({
    String userId = 'test_user_id',
    String loginId = 'test@example.com',
    bool isVerified = true,
  }) {
    return FakeAuthNotifier(
      AuthState.authenticated(
        User(id: userId, loginId: loginId, isVerified: isVerified),
      ),
    );
  }

  factory FakeAuthNotifier.unauthenticated([String message = '']) {
    return FakeAuthNotifier(AuthState.unauthenticated(message));
  }

  factory FakeAuthNotifier.loading() {
    return FakeAuthNotifier(const AuthState.loading());
  }

  @override
  Future<bool> signup({required String email, required String password}) async {
    _signupCalled = true;
    return true;
  }

  @override
  Future<void> login({required String email, required String password}) async {
    _loginCalled = true;
  }
}

/// テスト用のAuthService実装
/// FakeAuthNotifierが必要とする最小限の実装を提供
class _FakeAuthService implements AuthService {
  @override
  Stream<User?> get authStateChanges => Stream.empty();

  @override
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser() {
    throw UnimplementedError();
  }

  @override
  Future<User?> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<void> reauthenticate({required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmail({required String newEmail}) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword({required String newPassword}) {
    throw UnimplementedError();
  }

  @override
  Future<void> validateCurrentUserToken() {
    throw UnimplementedError();
  }
}

/// テスト用のCheckMemberExistsUseCase実装
class _FakeCheckMemberExistsUseCase implements CheckMemberExistsUseCase {
  @override
  Future<bool> execute(User user) async {
    return true; // テスト用に常にtrueを返す
  }
}

/// テスト用のCreateMemberFromUserUseCase実装
class _FakeCreateMemberFromUserUseCase implements CreateMemberFromUserUseCase {
  @override
  Future<bool> execute(User user) async {
    return true; // テスト用に常にtrueを返す
  }
}

/// テスト用のAcceptInvitationUseCase実装
class _FakeAcceptInvitationUseCase implements AcceptInvitationUseCase {
  @override
  Future<bool> execute(String invitationCode, String userId) async {
    return true; // テスト用に常にtrueを返す
  }
}
