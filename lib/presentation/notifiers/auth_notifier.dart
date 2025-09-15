import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/value_objects/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../application/interfaces/auth_service.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/member_invitation_repository.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../../infrastructure/repositories/firestore_member_invitation_repository.dart';
import '../../application/usecases/member/check_member_exists_usecase.dart';
import '../../application/usecases/member/create_member_from_user_usecase.dart';
import '../../application/usecases/member/accept_invitation_usecase.dart';
import '../../core/app_logger.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return FirestoreMemberRepository();
});

final memberInvitationRepositoryProvider = Provider<MemberInvitationRepository>(
  (ref) {
    return FirestoreMemberInvitationRepository(FirebaseFirestore.instance);
  },
);

final checkMemberExistsUseCaseProvider = Provider<CheckMemberExistsUseCase>((
  ref,
) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return CheckMemberExistsUseCase(memberRepository);
});

final createMemberFromUserUseCaseProvider =
    Provider<CreateMemberFromUserUseCase>((ref) {
      final memberRepository = ref.watch(memberRepositoryProvider);
      return CreateMemberFromUserUseCase(memberRepository);
    });

final acceptInvitationUseCaseProvider = Provider<AcceptInvitationUseCase>((
  ref,
) {
  final memberInvitationRepository = ref.watch(
    memberInvitationRepositoryProvider,
  );
  final memberRepository = ref.watch(memberRepositoryProvider);
  return AcceptInvitationUseCase(memberInvitationRepository, memberRepository);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final checkMemberExistsUseCase = ref.watch(checkMemberExistsUseCaseProvider);
  final createMemberFromUserUseCase = ref.watch(
    createMemberFromUserUseCaseProvider,
  );
  final acceptInvitationUseCase = ref.watch(acceptInvitationUseCaseProvider);

  final authNotifier = AuthNotifier(
    authService: authService,
    checkMemberExistsUseCase: checkMemberExistsUseCase,
    createMemberFromUserUseCase: createMemberFromUserUseCase,
    acceptInvitationUseCase: acceptInvitationUseCase,
  );

  authNotifier.initialize();

  return authNotifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required this.authService,
    required this.checkMemberExistsUseCase,
    required this.createMemberFromUserUseCase,
    required this.acceptInvitationUseCase,
  }) : super(const AuthState.loading());

  final AuthService authService;
  final CheckMemberExistsUseCase checkMemberExistsUseCase;
  final CreateMemberFromUserUseCase createMemberFromUserUseCase;
  final AcceptInvitationUseCase acceptInvitationUseCase;
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
    } catch (e, stack) {
      logger.e(
        'AuthNotifier._handleUnverifiedUser: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
    await _processUserMembership(user);
  }

  Future<void> _processUserMembership(User user) async {
    try {
      await authService.validateCurrentUserToken();

      final memberExists = await checkMemberExistsUseCase.execute(user);

      if (memberExists) {
        state = AuthState.authenticated(user);
        return;
      }

      state = AuthState.unauthenticated(
        'member_selection_required',
        messageType: MessageType.info,
      );
    } catch (e, stack) {
      logger.e(
        'AuthNotifier._processUserMembership: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      await _signOutWithError('認証が無効です。再度ログインしてください。');
    }
  }

  Future<void> createNewMember(User user) async {
    try {
      final success = await createMemberFromUserUseCase.execute(user);
      if (success) {
        state = AuthState.authenticated(user);
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

  Future<bool> acceptInvitation(String invitationCode, User user) async {
    try {
      final success = await acceptInvitationUseCase.execute(
        invitationCode,
        user.id,
      );
      if (!success) {
        return false;
      }
      state = AuthState.authenticated(user);
      return true;
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

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
