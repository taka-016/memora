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
import 'package:memora/application/usecases/member/get_member_by_account_id_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';

import '../../../../helpers/test_exception.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([
  ObserveAuthStateChangesUseCase,
  GetCurrentUserUseCase,
  LoginUseCase,
  LogoutUseCase,
  GetMemberByAccountIdUseCase,
  CreateMemberFromUserUseCase,
  AcceptInvitationUseCase,
])
void main() {
  group('AuthNotifier', () {
    late MockObserveAuthStateChangesUseCase mockObserveAuthStateChangesUseCase;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
    late MockLoginUseCase mockLoginUseCase;
    late MockLogoutUseCase mockLogoutUseCase;
    late MockGetMemberByAccountIdUseCase mockGetMemberByAccountIdUseCase;
    late MockCreateMemberFromUserUseCase mockCreateMemberFromUserUseCase;
    late MockAcceptInvitationUseCase mockAcceptInvitationUseCase;

    setUp(() {
      mockObserveAuthStateChangesUseCase = MockObserveAuthStateChangesUseCase();
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      mockLoginUseCase = MockLoginUseCase();
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
          getCurrentUserUseCaseProvider.overrideWithValue(
            mockGetCurrentUserUseCase,
          ),
          loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
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

    testWidgets('Google認証中の連続操作を抑えキャンセル後は再試行できる', (tester) async {
      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);
      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(null);
      await tester.pump();
      final pending = Completer<bool>();
      when(mockLoginUseCase.execute()).thenAnswer((_) => pending.future);

      final signingIn = notifier.login();
      expect(notifier.state.isLoading, isTrue);
      controller.add(null);
      await tester.pump();
      await notifier.login();
      verify(mockLoginUseCase.execute()).called(1);
      pending.complete(false);
      await signingIn;
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.message, isEmpty);

      when(mockLoginUseCase.execute()).thenAnswer((_) async => true);
      const user = UserDto(
        id: 'existing',
        loginId: 'test@example.com',
        isVerified: true,
      );
      when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
        (_) async => const MemberDto(id: 'member', displayName: '本人'),
      );
      await notifier.login();
      controller.add(user);
      await tester.pump();
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.member!.id, 'member');
      verify(mockLoginUseCase.execute()).called(1);
    });

    testWidgets('Google認証の失敗を表示して再試行できる', (tester) async {
      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);
      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(null);
      await tester.pump();
      when(mockLoginUseCase.execute()).thenThrow(TestException('通信失敗'));

      await notifier.login();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.message, contains('通信失敗'));
      expect(notifier.state.messageType, MessageType.error);

      when(mockLoginUseCase.execute()).thenAnswer((_) async => false);
      await notifier.login();
      expect(notifier.state.message, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      verify(mockLoginUseCase.execute()).called(2);
    });

    testWidgets('Google認証中に破棄されても遅延した結果で状態更新しない', (tester) async {
      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(null);
      await tester.pump();
      final pending = Completer<bool>();
      when(mockLoginUseCase.execute()).thenAnswer((_) => pending.future);
      final signingIn = notifier.login();
      container.dispose();
      pending.complete(false);
      await expectLater(signingIn, completes);
    });

    {
      testWidgets('起動時のメンバー確認を5回試してもタイムアウトした場合にログアウトせず手動再試行できる', (
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
        final pendingMember = Completer<MemberDto?>();
        when(mockGetMemberByAccountIdUseCase.execute(user.id))
            .thenAnswer((_) => pendingMember.future);
        when(mockGetCurrentUserUseCase.execute()).thenAnswer((_) async => user);
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
        when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
          (_) async => const MemberDto(id: 'member', displayName: '本人'),
        );
        final retry = notifier.retryInitialization();
        expect(notifier.state.isLoading, isTrue);
        await tester.pump();
        await retry;
        expect(notifier.state.user, user);
        expect(notifier.state.isAuthenticated, isTrue);
        pendingMember.complete(null);
        await tester.pump();
        expect(notifier.state.isAuthenticated, isTrue);
        verifyNever(mockLogoutUseCase.execute());
      });
    }

    {
      testWidgets('起動時のメンバー確認は一度のタイムアウト後に自動回復する', (tester) async {
        final previousLog = logger;
        logger = const SilentAppLog();
        addTearDown(() => logger = previousLog);
        const user = UserDto(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );
        final pendingMember = Completer<MemberDto?>();
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
        when(mockGetMemberByAccountIdUseCase.execute(user.id)).thenAnswer(
          (_) async => const MemberDto(id: 'member', displayName: '本人'),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
        verifyNever(mockLogoutUseCase.execute());
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
    });

    test('新規ユーザーのログイン時にmember_selection_required状態になる', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
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
      final memberCompleter = Completer<MemberDto?>();
      when(mockGetMemberByAccountIdUseCase.execute(user.id))
          .thenAnswer((_) => memberCompleter.future);

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

      memberCompleter.complete(null);
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
      expect(
        notifier.state.message,
        'Googleアカウントのメールアドレスを確認できませんでした。別のアカウントでログインしてください。',
      );

      signOutCompleter.complete();
      await Future(() {});
      await Future(() {});
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(
        notifier.state.message,
        'Googleアカウントのメールアドレスを確認できませんでした。別のアカウントでログインしてください。',
      );
    });

    test(
      'GetMemberByAccountIdUseCaseが例外を投げた場合はエラーでサインアウトしunauthenticatedになる',
      () async {
        const user = UserDto(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );
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
