import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:memora/application/usecases/account/signup_usecase.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
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

  ObserveAuthStateChangesUseCase get observeAuthStateChangesUseCase =>
      ref.read(observeAuthStateChangesUseCaseProvider);
  ValidateCurrentUserTokenUseCase get validateCurrentUserTokenUseCase =>
      ref.read(validateCurrentUserTokenUseCaseProvider);
  SendEmailVerificationUseCase get sendEmailVerificationUseCase =>
      ref.read(sendEmailVerificationUseCaseProvider);
  GetCurrentUserUseCase get getCurrentUserUseCase =>
      ref.read(getCurrentUserUseCaseProvider);
  LoginUseCase get loginUseCase => ref.read(loginUseCaseProvider);
  SignupUseCase get signupUseCase => ref.read(signupUseCaseProvider);
  LogoutUseCase get logoutUseCase => ref.read(logoutUseCaseProvider);
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
    _authStateSubscription = observeAuthStateChangesUseCase.execute().listen((
      user,
    ) {
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
      await sendEmailVerificationUseCase.execute();
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
      await _signOutWithError(
        '認証メールの送信に失敗しました。再度ログインしてください。',
        generation: generation,
      );
      return;
    }
    if (!_isLatestAuthStateChange(generation)) {
      return;
    }
    state = const AuthState.unauthenticated(
      '認証メールを再送しました。メールを確認して認証を完了してください。',
      messageType: MessageType.info,
    );
    await _signOut();
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
      await validateCurrentUserTokenUseCase.execute();
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
      await _signOutWithError('認証が無効です。再度ログインしてください。', generation: generation);
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
      await logoutUseCase.execute();
    } catch (e, stack) {
      logger.e(
        'AuthNotifier._signOut: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _signOutWithError(String message, {int? generation}) async {
    if (generation != null && !_isLatestAuthStateChange(generation)) {
      return;
    }
    state = AuthState.unauthenticated(message, messageType: MessageType.error);
    await _signOut();
  }

  Future<bool> _setAuthenticatedStateFromCurrentUser() async {
    try {
      final currentUser = await getCurrentUserUseCase.execute();
      if (currentUser == null) {
        await _signOutWithError('認証情報の取得に失敗しました。再度ログインしてください。');
        return false;
      }
      state = AuthState.authenticated(currentUser);
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
      await loginUseCase.execute(email: email, password: password);
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
      await signupUseCase.execute(email: email, password: password);
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
