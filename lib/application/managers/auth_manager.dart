import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';
import '../usecases/get_or_create_member_usecase.dart';

class AuthManager extends ChangeNotifier {
  AuthManager({required this.authService, this.getOrCreateMemberUseCase})
    : _state = const AuthState.loading();

  final AuthService authService;
  final GetOrCreateMemberUseCase? getOrCreateMemberUseCase;
  AuthState _state;
  StreamSubscription<User?>? _authStateSubscription;

  AuthState get state => _state;

  Future<void> initialize() async {
    _authStateSubscription = authService.authStateChanges.listen((user) async {
      if (user != null) {
        // 認証状態変更時にメンバー取得・作成処理を実行
        if (getOrCreateMemberUseCase != null) {
          try {
            // トークンを明示的にリフレッシュしてからメンバー取得を実行
            await authService.validateCurrentUserToken();
            await getOrCreateMemberUseCase!.execute(user);
            _updateState(AuthState.authenticated(user));
          } catch (e) {
            // エラーの場合、強制ログアウトして再認証を促す
            await authService.signOut();
            _updateState(const AuthState.error('認証が無効です。再度ログインしてください。'));
          }
        } else {
          _updateState(AuthState.authenticated(user));
        }
      } else {
        _updateState(const AuthState.unauthenticated());
      }
    });
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _updateState(const AuthState.loading());
      await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 認証成功時の状態更新はauthStateChangesリスナーで自動的に処理される
    } catch (e) {
      _updateState(AuthState.error(_getFirebaseErrorMessage(e.toString())));
    }
  }

  Future<void> signup({required String email, required String password}) async {
    try {
      _updateState(const AuthState.loading());
      await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 認証成功時の状態更新はauthStateChangesリスナーで自動的に処理される
    } catch (e) {
      _updateState(AuthState.error(_getFirebaseErrorMessage(e.toString())));
    }
  }

  Future<void> logout() async {
    try {
      _updateState(const AuthState.loading());
      await authService.signOut();
      // 認証成功時の状態更新はauthStateChangesリスナーで自動的に処理される
    } catch (e) {
      _updateState(AuthState.error('ログアウトに失敗しました: ${e.toString()}'));
    }
  }

  void clearError() {
    if (_state.status == AuthStatus.error) {
      _updateState(const AuthState.unauthenticated());
    }
  }

  String _getFirebaseErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'このメールアドレスは既に使用されています。別のメールアドレスを使用するか、ログインしてください。';
    } else if (error.contains('weak-password')) {
      return 'パスワードが弱すぎます。より強力なパスワードを設定してください。';
    } else if (error.contains('invalid-email')) {
      return '無効なメールアドレスです。正しいメールアドレスを入力してください。';
    } else if (error.contains('user-not-found')) {
      return 'ユーザーが見つかりません。メールアドレスを確認してください。';
    } else if (error.contains('wrong-password')) {
      return 'パスワードが間違っています。';
    } else if (error.contains('user-disabled')) {
      return 'このアカウントは無効になっています。';
    } else if (error.contains('too-many-requests')) {
      return 'リクエストが多すぎます。しばらく時間をおいてから再試行してください。';
    } else {
      return 'エラーが発生しました。しばらく時間をおいてから再試行してください。';
    }
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
