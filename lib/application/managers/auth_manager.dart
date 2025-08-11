import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
        // メール認証チェック
        if (!user.isVerified) {
          // メール認証が未完了の場合、認証メールを再送する
          try {
            await authService.sendEmailVerification();
            await authService.signOut();
            _updateState(
              const AuthState.unauthenticated(
                '認証メールを再送しました。メールを確認して認証を完了してください。',
                messageType: MessageType.info,
              ),
            );
          } catch (e) {
            await authService.signOut();
            _updateState(
              const AuthState.unauthenticated(
                '認証メールの送信に失敗しました。再度ログインしてください。',
                messageType: MessageType.error,
              ),
            );
          }
          return;
        }

        // 認証状態変更時にメンバー取得・作成処理を実行
        if (getOrCreateMemberUseCase != null) {
          try {
            // トークンを明示的にリフレッシュしてからメンバー取得を実行
            await authService.validateCurrentUserToken();
            final result = await getOrCreateMemberUseCase!.execute(user);
            if (result) {
              _updateState(AuthState.authenticated(user));
            } else {
              // GetOrCreateMemberUseCaseがfalseを返した場合、強制ログアウト
              await authService.signOut();
              _updateState(
                const AuthState.unauthenticated(
                  '認証が無効です。再度ログインしてください。',
                  messageType: MessageType.error,
                ),
              );
            }
          } catch (e) {
            // エラーの場合、強制ログアウトして再認証を促す
            await authService.signOut();
            _updateState(
              const AuthState.unauthenticated(
                '認証が無効です。再度ログインしてください。',
                messageType: MessageType.error,
              ),
            );
          }
        } else {
          _updateState(AuthState.authenticated(user));
        }
      } else {
        _updateState(const AuthState.unauthenticated(''));
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      _updateState(
        AuthState.unauthenticated(
          _getFirebaseErrorMessage(e),
          messageType: MessageType.error,
        ),
      );
    } catch (e) {
      _updateState(
        AuthState.unauthenticated(e.toString(), messageType: MessageType.error),
      );
    }
  }

  Future<void> signup({required String email, required String password}) async {
    try {
      _updateState(const AuthState.loading());
      await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await authService.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _updateState(
        AuthState.unauthenticated(
          _getFirebaseErrorMessage(e),
          messageType: MessageType.error,
        ),
      );
    } catch (e) {
      _updateState(
        AuthState.unauthenticated(e.toString(), messageType: MessageType.error),
      );
    }
  }

  Future<void> logout() async {
    try {
      _updateState(const AuthState.loading());
      await authService.signOut();
      // 認証成功時の状態更新はauthStateChangesリスナーで自動的に処理される
    } catch (e) {
      _updateState(
        AuthState.unauthenticated(
          'ログアウトに失敗しました: ${e.toString()}',
          messageType: MessageType.error,
        ),
      );
    }
  }

  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。ログインするか別のメールを利用してください。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'operation-not-allowed':
        return 'このサインイン方法は無効です。コンソールで有効化が必要です。';
      case 'weak-password':
        return 'パスワードが弱すぎます。より強力なパスワードを設定してください。';
      case 'user-disabled':
        return 'このアカウントは無効化されています。';
      case 'user-not-found':
        return 'ユーザーが見つかりません。メールアドレスを確認してください。';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらくしてから再試行してください。';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました。通信環境を確認してください。';
      case 'requires-recent-login':
        return 'この操作には再ログインが必要です。いったんログアウトして再度ログインしてください。';
      case 'invalid-credential':
        return '認証情報が無効または期限切れです。やり直してください。';
      case 'account-exists-with-different-credential':
        return 'このメールは別のログイン方法で登録済みです。連携サインインを試してください。';
      case 'credential-already-in-use':
        return 'その認証情報は既に他のアカウントで使用されています。';
      case 'provider-already-linked':
        return 'このプロバイダは既にリンク済みです。';
      case 'no-such-provider':
        return 'リンクされていないプロバイダです。';
      case 'invalid-verification-code':
        return '確認コードが正しくありません。';
      case 'invalid-verification-id':
        return '確認IDが正しくありません。';
      case 'session-expired':
        return '確認コードの有効期限が切れています。再送信してください。';
      case 'missing-email':
        return 'メールアドレスを入力してください。';
      default:
        return error.message ?? 'エラーが発生しました。時間をおいて再試行してください。';
    }
  }

  void clearError() {
    _state = _state.copyWith(message: '');
    notifyListeners();
  }

  void _updateState(AuthState newState) {
    if (newState.status == AuthStatus.unauthenticated &&
        (newState.message.isEmpty)) {
      newState = newState.copyWith(message: _state.message);
    }
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
