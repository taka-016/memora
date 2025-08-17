import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:memora/domain/value-objects/auth_state.dart';

/// テスト用のFakeAuthManager
///
/// StateNotifierとして正常に動作するテスト専用のAuthManager実装
/// 他のテストファイルからも利用可能
class FakeAuthManager extends AuthManager {
  FakeAuthManager(AuthState initialState)
    : super(authService: _FakeAuthService(), getOrCreateMemberUseCase: null) {
    state = initialState;
  }

  /// 認証済み状態のFakeAuthManagerを作成するファクトリーメソッド
  factory FakeAuthManager.authenticated({
    String userId = 'test_user_id',
    String loginId = 'test@example.com',
    bool isVerified = true,
  }) {
    return FakeAuthManager(
      AuthState.authenticated(
        User(id: userId, loginId: loginId, isVerified: isVerified),
      ),
    );
  }

  /// 未認証状態のFakeAuthManagerを作成するファクトリーメソッド
  factory FakeAuthManager.unauthenticated([String message = '']) {
    return FakeAuthManager(AuthState.unauthenticated(message));
  }

  /// ローディング状態のFakeAuthManagerを作成するファクトリーメソッド
  factory FakeAuthManager.loading() {
    return FakeAuthManager(const AuthState.loading());
  }
}

/// テスト用のAuthService実装
/// FakeAuthManagerが必要とする最小限の実装を提供
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
  Future<void> sendSignInLinkToEmail({required String email}) {
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
  Future<User> signInWithEmailLink({
    required String email,
    required String emailLink,
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
