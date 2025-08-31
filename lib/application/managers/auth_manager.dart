import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/value_objects/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/repositories/member_repository.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../usecases/get_or_create_member_usecase.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return FirestoreMemberRepository();
});

final getOrCreateMemberUseCaseProvider = Provider<GetOrCreateMemberUseCase>((
  ref,
) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return GetOrCreateMemberUseCase(memberRepository);
});

final authManagerProvider = StateNotifierProvider<AuthManager, AuthState>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final getOrCreateMemberUseCase = ref.watch(getOrCreateMemberUseCaseProvider);

  final authManager = AuthManager(
    authService: authService,
    getOrCreateMemberUseCase: getOrCreateMemberUseCase,
  );

  authManager.initialize();

  return authManager;
});

class AuthManager extends StateNotifier<AuthState> {
  AuthManager({required this.authService, this.getOrCreateMemberUseCase})
    : super(const AuthState.loading());

  final AuthService authService;
  final GetOrCreateMemberUseCase? getOrCreateMemberUseCase;
  StreamSubscription<User?>? _authStateSubscription;

  Future<void> initialize() async {
    _authStateSubscription = authService.authStateChanges.listen((user) async {
      if (user == null) {
        await _handleUnauthenticatedUser();
        return;
      }
      await _handleAuthenticatedUser(user);
    });
  }

  Future<void> _handleAuthenticatedUser(User user) async {
    if (!user.isVerified) {
      await _handleUnverifiedUser();
      return;
    }
    await _handleVerifiedUser(user);
  }

  Future<void> _handleUnverifiedUser() async {
    try {
      await authService.sendEmailVerification();
    } catch (e) {
      await _signOutWithError('認証メールの送信に失敗しました。再度ログインしてください。');
      return;
    }
    await _signOut();
    state = const AuthState.unauthenticated(
      '認証メールを再送しました。メールを確認して認証を完了してください。',
      messageType: MessageType.info,
    );
  }

  Future<void> _handleVerifiedUser(User user) async {
    if (getOrCreateMemberUseCase == null) {
      state = AuthState.authenticated(user);
      return;
    }
    await _processUserMembership(user);
  }

  Future<void> _processUserMembership(User user) async {
    try {
      await authService.validateCurrentUserToken();
      final result = await getOrCreateMemberUseCase!.execute(user);
      if (!result) {
        await _signOutWithError('認証が無効です。再度ログインしてください。');
        return;
      }
      state = AuthState.authenticated(user);
    } catch (e) {
      await _signOutWithError('認証が無効です。再度ログインしてください。');
    }
  }

  Future<void> _signOut() async {
    try {
      await authService.signOut();
    } catch (e) {
      debugPrint('サインアウト失敗: $e');
    }
  }

  Future<void> _signOutWithError(String message) async {
    await _signOut();
    state = AuthState.unauthenticated(message, messageType: MessageType.error);
  }

  Future<void> _handleUnauthenticatedUser() async {
    // 現在の状態がメッセージ付きunauthenticatedの場合はメッセージを保持
    if (state.status == AuthStatus.unauthenticated &&
        state.message.isNotEmpty) {
      return;
    }
    state = const AuthState.unauthenticated('');
  }

  Future<void> login({required String email, required String password}) async {
    try {
      state = const AuthState.loading();
      await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 状態更新はauthStateChangesリスナーで自動的に処理される
    } catch (e) {
      state = AuthState.unauthenticated(
        e.toString(),
        messageType: MessageType.error,
      );
    }
  }

  Future<bool> signup({required String email, required String password}) async {
    bool isSuccess = false;
    try {
      state = const AuthState.loading();
      await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      isSuccess = true;
      // 状態更新はauthStateChangesリスナーで自動的に処理される
    } catch (e) {
      state = AuthState.unauthenticated(
        e.toString(),
        messageType: MessageType.error,
      );
    }
    return isSuccess;
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    await _signOut();
    // 状態更新はauthStateChangesリスナーで自動的に処理される
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
