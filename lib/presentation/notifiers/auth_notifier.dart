import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/mappers/account/user_mapper.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

typedef AuthViewState = AuthState;

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<UserDto?>? _authStateSubscription;
  int _authStateChangeGeneration = 0;

  AuthService get authService => ref.read(authServiceProvider);
  CheckMemberExistsUseCase get checkMemberExistsUseCase =>
      ref.read(checkMemberExistsUseCaseProvider);
  CreateMemberFromUserUseCase get createMemberFromUserUseCase =>
      ref.read(createMemberFromUserUseCaseProvider);
  AcceptInvitationUseCase get acceptInvitationUseCase =>
      ref.read(acceptInvitationUseCaseProvider);

  @override
  AuthState build() {
    _authStateSubscription?.cancel();
    _authStateChangeGeneration++;
    _authStateSubscription = authService.authStateChanges
        .map((user) => user == null ? null : UserMapper.toDto(user))
        .listen((user) {
          final generation = ++_authStateChangeGeneration;
          unawaited(_handleAuthStateChange(user, generation));
        });

    ref.onDispose(() {
      _authStateChangeGeneration++;
      _authStateSubscription?.cancel();
      _authStateSubscription = null;
    });

    return const AuthState.loading();
  }

  Future<void> _handleUnverifiedUser(int generation) async {
    if (!_isLatestAuthStateChange(generation)) {
      return;
    }
    try {
      await authService.sendEmailVerification();
      if (!_isLatestAuthStateChange(generation)) {
        return;
      }
    } catch (e, stack) {
      logger.e(
        'AuthNotifier._handleUnverifiedUser: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (!_isLatestAuthStateChange(generation)) {
        return;
      }
      await _signOutWithError('認証メールの送信に失敗しました。再度ログインしてください。');
      return;
    }
    if (!_isLatestAuthStateChange(generation)) {
      return;
    }
    await _signOut();
    if (!_isLatestAuthStateChange(generation)) {
      return;
    }
    state = const AuthState.unauthenticated(
      '認証メールを再送しました。メールを確認して認証を完了してください。',
      messageType: MessageType.info,
    );
  }

  Future<void> _handleAuthStateChange(UserDto? user, int generation) async {
    if (!_isLatestAuthStateChange(generation)) {
      return;
    }

    if (user == null) {
      await _handleUnauthenticatedUser();
      return;
    }

    if (!user.isVerified) {
      await _handleUnverifiedUser(generation);
      return;
    }

    try {
      await authService.validateCurrentUserToken();
      if (!_isLatestAuthStateChange(generation)) {
        return;
      }

      final memberExists = await checkMemberExistsUseCase.execute(user.id);
      if (!_isLatestAuthStateChange(generation)) {
        return;
      }

      if (memberExists) {
        state = AuthState.authenticated(user);
        return;
      }

      state = AuthState.unauthenticated(
        memberSelectionRequiredMessage,
        messageType: MessageType.info,
      );
    } catch (e, stack) {
      logger.e(
        'AuthNotifier.authStateChanges: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (!_isLatestAuthStateChange(generation)) {
        return;
      }
      await _signOutWithError('認証が無効です。再度ログインしてください。');
    }
  }

  bool _isLatestAuthStateChange(int generation) {
    return generation == _authStateChangeGeneration;
  }

  Future<void> createNewMember(UserDto user) async {
    try {
      final success = await createMemberFromUserUseCase.execute(user);
      if (success) {
        await _setAuthenticatedStateFromCurrentUser();
      } else {
        await _signOutWithError('メンバー作成に失敗しました。');
      }
    } catch (e, stack) {
      logger.e(
        'AuthNotifier.createNewMember: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      await _signOutWithError('メンバー作成に失敗しました。');
    }
  }

  Future<bool> acceptInvitation(
    String invitationCode, {
    required String userId,
  }) async {
    try {
      final success = await acceptInvitationUseCase.execute(
        invitationCode,
        userId,
      );
      if (!success) {
        return false;
      }
      return await _setAuthenticatedStateFromCurrentUser();
    } catch (e, stack) {
      logger.e(
        'AuthNotifier.acceptInvitation: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<void> _signOut() async {
    try {
      await authService.signOut();
    } catch (e, stack) {
      logger.e(
        'AuthNotifier._signOut: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _signOutWithError(String message) async {
    await _signOut();
    state = AuthState.unauthenticated(message, messageType: MessageType.error);
  }

  Future<bool> _setAuthenticatedStateFromCurrentUser() async {
    try {
      final currentUser = await authService.getCurrentUser();
      if (currentUser == null) {
        await _signOutWithError('認証情報の取得に失敗しました。再度ログインしてください。');
        return false;
      }
      state = AuthState.authenticated(UserMapper.toDto(currentUser));
      return true;
    } catch (e, stack) {
      logger.e(
        'AuthNotifier._setAuthenticatedStateFromCurrentUser: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      await _signOutWithError('認証情報の取得に失敗しました。再度ログインしてください。');
      return false;
    }
  }

  Future<void> _handleUnauthenticatedUser() async {
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
    } catch (e, stack) {
      logger.e(
        'AuthNotifier.login: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
    } catch (e, stack) {
      logger.e(
        'AuthNotifier.signup: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
}
