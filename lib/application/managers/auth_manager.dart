import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/firebase_error_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value-objects/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';
import '../usecases/get_or_create_member_usecase.dart';

class AuthManager extends StateNotifier<AuthState> {
  AuthManager({required this.authService, this.getOrCreateMemberUseCase})
    : super(const AuthState.loading());

  final AuthService authService;
  final GetOrCreateMemberUseCase? getOrCreateMemberUseCase;
  StreamSubscription<User?>? _authStateSubscription;

  Future<void> initialize() async {
    _authStateSubscription = authService.authStateChanges.listen((user) async {
      if (user != null) {
        // メール認証チェック
        if (!user.isVerified) {
          // メール認証が未完了の場合、認証メールを再送する
          try {
            await authService.sendEmailVerification();
            await authService.signOut();
            state = const AuthState.unauthenticated(
              '認証メールを再送しました。メールを確認して認証を完了してください。',
              messageType: MessageType.info,
            );
          } catch (e) {
            await authService.signOut();
            state = const AuthState.unauthenticated(
              '認証メールの送信に失敗しました。再度ログインしてください。',
              messageType: MessageType.error,
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
              state = AuthState.authenticated(user);
            } else {
              // GetOrCreateMemberUseCaseがfalseを返した場合、強制ログアウト
              await authService.signOut();
              state = const AuthState.unauthenticated(
                '認証が無効です。再度ログインしてください。',
                messageType: MessageType.error,
              );
            }
          } catch (e) {
            // エラーの場合、強制ログアウトして再認証を促す
            await authService.signOut();
            state = const AuthState.unauthenticated(
              '認証が無効です。再度ログインしてください。',
              messageType: MessageType.error,
            );
          }
        } else {
          state = AuthState.authenticated(user);
        }
      } else {
        // 現在の状態がメッセージ付きのunauthenticatedの場合はメッセージを保持
        if (state.status == AuthStatus.unauthenticated &&
            state.message.isNotEmpty) {
          return;
        }
        state = const AuthState.unauthenticated('');
      }
    });
  }

  Future<void> login({required String email, required String password}) async {
    try {
      state = const AuthState.loading();
      await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 状態更新はauthStateChangesリスナーで自動的に処理される
    } on firebase_auth.FirebaseAuthException catch (e) {
      state = AuthState.unauthenticated(
        FirebaseErrorUtil.getFirebaseErrorMessage(e),
        messageType: MessageType.error,
      );
    } catch (e) {
      state = AuthState.unauthenticated(
        e.toString(),
        messageType: MessageType.error,
      );
    }
  }

  Future<void> signup({required String email, required String password}) async {
    try {
      state = const AuthState.loading();
      await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await authService.signOut();
      // 状態更新はauthStateChangesリスナーで自動的に処理される
    } on firebase_auth.FirebaseAuthException catch (e) {
      state = AuthState.unauthenticated(
        FirebaseErrorUtil.getFirebaseErrorMessage(e),
        messageType: MessageType.error,
      );
    } catch (e) {
      state = AuthState.unauthenticated(
        e.toString(),
        messageType: MessageType.error,
      );
    }
  }

  Future<void> logout() async {
    try {
      state = const AuthState.loading();
      await authService.signOut();
      // 状態更新はauthStateChangesリスナーで自動的に処理される
    } on firebase_auth.FirebaseAuthException catch (e) {
      state = AuthState.unauthenticated(
        FirebaseErrorUtil.getFirebaseErrorMessage(e),
        messageType: MessageType.error,
      );
    } catch (e) {
      state = AuthState.unauthenticated(
        e.toString(),
        messageType: MessageType.error,
      );
    }
  }

  void clearError() {
    state = state.copyWith(message: '');
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
