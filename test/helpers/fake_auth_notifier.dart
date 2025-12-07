import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/domain/value_objects/auth_state.dart';

/// テスト用のFakeAuthNotifier
///
/// AuthNotifierを差し替えてUIの動作を検証するための簡易実装
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._initialState);

  final AuthState _initialState;
  bool _signupCalled = false;
  bool _loginCalled = false;
  bool _logoutCalled = false;

  bool get signupCalled => _signupCalled;
  bool get loginCalled => _loginCalled;
  bool get logoutCalled => _logoutCalled;

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
  AuthState build() {
    return _initialState;
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

  @override
  Future<void> logout() async {
    _logoutCalled = true;
    state = const AuthState.unauthenticated('');
  }
}
