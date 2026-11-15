import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/composition_root/providers/account_providers.dart';

import 'dart:async';

import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/logging/device_app_log.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:memora/application/usecases/account/signup_usecase.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
import 'package:memora/application/usecases/member/get_member_by_account_id_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';

import '../../../../helpers/test_exception.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([
  ObserveAuthStateChangesUseCase,
  ValidateCurrentUserTokenUseCase,
  SendEmailVerificationUseCase,
  GetCurrentUserUseCase,
  LoginUseCase,
  SignupUseCase,
  LogoutUseCase,
  GetMemberByAccountIdUseCase,
  CreateMemberFromUserUseCase,
  AcceptInvitationUseCase,
])
void main() {
  group('AuthNotifier', () {
    late MockObserveAuthStateChangesUseCase mockObserveAuthStateChangesUseCase;
    late MockValidateCurrentUserTokenUseCase
    mockValidateCurrentUserTokenUseCase;
    late MockSendEmailVerificationUseCase mockSendEmailVerificationUseCase;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
    late MockLoginUseCase mockLoginUseCase;
    late MockSignupUseCase mockSignupUseCase;
    late MockLogoutUseCase mockLogoutUseCase;
    late MockGetMemberByAccountIdUseCase mockGetMemberByAccountIdUseCase;
    late MockCreateMemberFromUserUseCase mockCreateMemberFromUserUseCase;
    late MockAcceptInvitationUseCase mockAcceptInvitationUseCase;

    setUp(() {
      mockObserveAuthStateChangesUseCase = MockObserveAuthStateChangesUseCase();
      mockValidateCurrentUserTokenUseCase =
          MockValidateCurrentUserTokenUseCase();
      mockSendEmailVerificationUseCase = MockSendEmailVerificationUseCase();
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      mockLoginUseCase = MockLoginUseCase();
      mockSignupUseCase = MockSignupUseCase();
      mockLogoutUseCase = MockLogoutUseCase();
      mockGetMemberByAccountIdUseCase = MockGetMemberByAccountIdUseCase();
      mockCreateMemberFromUserUseCase = MockCreateMemberFromUserUseCase();
      mockAcceptInvitationUseCase = MockAcceptInvitationUseCase();
    });

    ProviderContainer createContainer(Stream<UserDto?> authStateStream) {
      when(mockObserveAuthStateChangesUseCase.execute())
          .thenAnswer((_) => authStateStream);

      return ProviderContainer(
        overrides: [
          observeAuthStateChangesUseCaseProvider.overrideWithValue(
            mockObserveAuthStateChangesUseCase,
          ),
          validateCurrentUserTokenUseCaseProvider.overrideWithValue(
            mockValidateCurrentUserTokenUseCase,
          ),
          sendEmailVerificationUseCaseProvider.overrideWithValue(
            mockSendEmailVerificationUseCase,
          ),
          getCurrentUserUseCaseProvider.overrideWithValue(
            mockGetCurrentUserUseCase,
          ),
          loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          signupUseCaseProvider.overrideWithValue(mockSignupUseCase),
          logoutUseCaseProvider.overrideWithValue(mockLogoutUseCase),
          getMemberByAccountIdUseCaseProvider.overrideWithValue(
            mockGetMemberByAccountIdUseCase,
          ),
          createMemberFromUserUseCaseProvider.overrideWithValue(
            mockCreateMemberFromUserUseCase,
          ),
          acceptInvitationUseCaseProvider.overrideWithValue(
            mockAcceptInvitationUseCase,
          ),
        ],
      );
    }

    for (final waitForToken in [false]) {
      testWidgets(
        '起動時の${waitForToken ? 'トークン' : 'メンバー'}確認を5回試してもタイムアウトした場合にログアウトせず手動再試行できる',
        (tester) async {
          final previousLog = logger;
          logger = const SilentAppLog();
          addTearDown(() => logger = previousLog);
          const user = UserDto(
            id: 'user123',
            loginId: 'test@example.com',
            isVerified: true,
          );
          final pendingToken = Completer<void>();
          final pendingMember = Completer<MemberDto?>();
          when(mockValidateCurrentUserTokenUseCase.execute()).thenAnswer(
            (_) => waitForToken ? pendingToken.future : Future.value(),
          );
          when(mockGetMemberByAccountIdUseCase.execute(user.id))
              .thenAnswer((_) => pendingMember.future);
          when(mockGetCurrentUserUseCase.execute())
              .thenAnswer((_) async => user);
          final controller = StreamController<UserDto?>();
          addTearDown(controller.close);
          final container = createContainer(controller.stream);
          addTearDown(container.dispose);
          final notifier = container.read(authNotifierProvider.notifier);
          controller.add(user);
          await tester.pump();
          expect(notifier.state.isLoading, isTrue);
          for (var attempt = 1; attempt <= 5; attempt++) {
            await tester.pump(const Duration(seconds: 15));
            if (attempt < 5) {
              expect(notifier.state.isLoading, isTrue);
              expect(notifier.state.hasInitializationError, isFalse);
              await tester.pump(const Duration(milliseconds: 500));
            }
          }
          expect(notifier.state.hasInitializationError, isTrue);
          verify(mockGetMemberByAccountIdUseCase.execute(user.id)).called(5);
          verifyNever(mockLogoutUseCase.execute());
          when(mockValidateCurrentUserTokenUseCase.execute())
              .thenAnswer((_) async {});
          when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
            (_) async => const MemberDto(id: 'member', displayName: '本人'),
          );
          final retry = notifier.retryInitialization();
          expect(notifier.state.isLoading, isTrue);
          await tester.pump();
          await retry;
          expect(notifier.state.user, user);
          expect(notifier.state.isAuthenticated, isTrue);
          pendingToken.complete();
          pendingMember.complete(null);
          await tester.pump();
          expect(notifier.state.isAuthenticated, isTrue);
          verifyNever(mockLogoutUseCase.execute());
        },
      );
    }

    for (final waitForToken in [false]) {
      testWidgets('起動時の${waitForToken ? 'トークン' : 'メンバー'}確認は一度のタイムアウト後に自動回復する', (
        tester,
      ) async {
        final previousLog = logger;
        logger = const SilentAppLog();
        addTearDown(() => logger = previousLog);
        const user = UserDto(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );
        final pendingToken = Completer<void>();
        final pendingMember = Completer<MemberDto?>();
        when(mockValidateCurrentUserTokenUseCase.execute()).thenAnswer(
          (_) => waitForToken ? pendingToken.future : Future.value(),
        );
        when(mockGetMemberByAccountIdUseCase.execute(user.id))
            .thenAnswer((_) => pendingMember.future);
        final controller = StreamController<UserDto?>();
        addTearDown(controller.close);
        final container = createContainer(controller.stream);
        addTearDown(container.dispose);
        container.read(authNotifierProvider);
        controller.add(user);
        await tester.pump();
        await tester.pump(const Duration(seconds: 15));
        expect(container.read(authNotifierProvider).isLoading, isTrue);
        expect(
          container.read(authNotifierProvider).hasInitializationError,
          isFalse,
        );
        when(mockValidateCurrentUserTokenUseCase.execute())
            .thenAnswer((_) async {});
        when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
          (_) async => const MemberDto(id: 'member', displayName: '本人'),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
        verifyNever(mockLogoutUseCase.execute());
        pendingToken.complete();
        pendingMember.complete(null);
        await tester.pump();
        expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
      });
    }

    testWidgets('認証の自動再試行待ちにログアウト通知が来たら古い確認を再開しない', (tester) async {
      final previousLog = logger;
      logger = const SilentAppLog();
      addTearDown(() => logger = previousLog);
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final pending = Completer<MemberDto?>();
      when(mockGetMemberByAccountIdUseCase.execute(user.id))
          .thenAnswer((_) => pending.future);
      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);
      container.read(authNotifierProvider);
      controller.add(user);
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));
      controller.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        container.read(authNotifierProvider).status,
        AuthStatus.unauthenticated,
      );
      verify(mockGetMemberByAccountIdUseCase.execute(user.id)).called(1);
      pending.complete(null);
      await tester.pump();
      expect(
        container.read(authNotifierProvider).status,
        AuthStatus.unauthenticated,
      );
    });

    test('初期状態はloading', () {
      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);

      expect(state.status, AuthStatus.loading);
      verify(mockObserveAuthStateChangesUseCase.execute()).called(1);
    });

    test('トークンを強制更新せず本人確認でauthenticated状態になる', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(mockValidateCurrentUserTokenUseCase.execute())
          .thenAnswer((_) async {});
      when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
        (_) async => const MemberDto(id: 'member', displayName: '本人'),
      );

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      expect(notifier.state.status, AuthStatus.authenticated);
      verify(mockGetMemberByAccountIdUseCase.execute(user.id)).called(1);
      verifyNever(mockValidateCurrentUserTokenUseCase.execute());
    });

    test('新規ユーザーのログイン時にmember_selection_required状態になる', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(mockValidateCurrentUserTokenUseCase.execute())
          .thenAnswer((_) async {});
      when(mockGetMemberByAccountIdUseCase.execute(user.id))
          .thenAnswer((_) async => null);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, memberSelectionRequiredMessage);
    });

    test('認証イベントが連続した場合でも新しいイベントが即時に優先される', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final validateCompleter = Completer<void>();

      when(mockValidateCurrentUserTokenUseCase.execute())
          .thenAnswer((_) => validateCompleter.future);
      when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
        (_) async => const MemberDto(id: 'member', displayName: '本人'),
      );

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller
        ..add(user)
        ..add(null);
      await Future(() {});
      await Future(() {});

      // nullイベントは先行イベントの完了を待たずに反映される
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '');

      validateCompleter.complete();
      await Future(() {});
      await Future(() {});

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '');
    });

    test('サインアウト中にnullイベントが来ても認証エラーメッセージを保持する', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final signOutCompleter = Completer<void>();

      when(mockGetMemberByAccountIdUseCase.execute(user.id))
          .thenThrow(TestException('本人確認失敗'));
      when(mockLogoutUseCase.execute())
          .thenAnswer((_) => signOutCompleter.future);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      controller.add(null);
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '認証が無効です。再度ログインしてください。');

      signOutCompleter.complete();
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '認証が無効です。再度ログインしてください。');
    });

    test('サインアウト中にnullイベントが来ても未認証ユーザーエラーメッセージを保持する', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: false,
      );
      final signOutCompleter = Completer<void>();

      when(mockSendEmailVerificationUseCase.execute())
          .thenThrow(TestException('send mail failed'));
      when(mockLogoutUseCase.execute())
          .thenAnswer((_) => signOutCompleter.future);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      controller.add(null);
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '認証メールの送信に失敗しました。再度ログインしてください。');

      signOutCompleter.complete();
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '認証メールの送信に失敗しました。再度ログインしてください。');
    });

    test('サインアウト中にnullイベントが来ても認証メール再送メッセージを保持する', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: false,
      );
      final signOutCompleter = Completer<void>();

      when(mockSendEmailVerificationUseCase.execute()).thenAnswer((_) async {});
      when(mockLogoutUseCase.execute())
          .thenAnswer((_) => signOutCompleter.future);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});
      await Future(() {});

      controller.add(null);
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '認証メールを再送しました。メールを確認して認証を完了してください。');
      expect(notifier.state.messageType, MessageType.info);

      signOutCompleter.complete();
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, '認証メールを再送しました。メールを確認して認証を完了してください。');
      expect(notifier.state.messageType, MessageType.info);
    });

    test(
      'GetMemberByAccountIdUseCaseが例外を投げた場合はエラーでサインアウトしunauthenticatedになる',
      () async {
        const user = UserDto(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );

        when(mockValidateCurrentUserTokenUseCase.execute())
            .thenAnswer((_) async {});
        when(mockGetMemberByAccountIdUseCase.execute(user.id))
            .thenThrow(TestException('Firestore error'));
        when(mockLogoutUseCase.execute()).thenAnswer((_) async {});

        final controller = StreamController<UserDto?>();
        addTearDown(controller.close);
        final container = createContainer(controller.stream);
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        controller.add(user);
        await Future(() {});

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.message, '認証が無効です。再度ログインしてください。');
        verify(mockLogoutUseCase.execute()).called(1);
      },
    );

    test('createNewMemberが成功した場合authenticated状態になる', () async {
      const userDto = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(mockCreateMemberFromUserUseCase.execute(userDto))
          .thenAnswer((_) async => true);
      when(mockGetCurrentUserUseCase.execute())
          .thenAnswer((_) async => userDto);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.createNewMember(userDto);

      expect(notifier.state.status, AuthStatus.authenticated);
      verify(mockCreateMemberFromUserUseCase.execute(userDto)).called(1);
    });

    test('acceptInvitationが成功した場合authenticated状態になる', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      const invitationCode = 'test-code';

      when(mockAcceptInvitationUseCase.execute(invitationCode, user.id))
          .thenAnswer((_) async => true);
      when(mockGetCurrentUserUseCase.execute()).thenAnswer((_) async => user);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.acceptInvitation(
        invitationCode,
        userId: user.id,
      );

      expect(result, true);
      expect(notifier.state.status, AuthStatus.authenticated);
      verify(mockAcceptInvitationUseCase.execute(invitationCode, user.id))
          .called(1);
    });

    test('acceptInvitationが失敗した場合falseを返し認証状態は保持される', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      const invitationCode = 'invalid-code';

      when(mockAcceptInvitationUseCase.execute(invitationCode, user.id))
          .thenAnswer((_) async => false);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      notifier.state = AuthState.authenticated(
        const UserDto(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        ),
      );

      final result = await notifier.acceptInvitation(
        invitationCode,
        userId: user.id,
      );

      expect(result, false);
      expect(notifier.state.status, AuthStatus.authenticated);
    });

    test('ログアウト時はloading状態になる', () async {
      when(mockLogoutUseCase.execute()).thenAnswer((_) async {});

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.loading);
      verify(mockLogoutUseCase.execute()).called(1);
    });
  });
}
