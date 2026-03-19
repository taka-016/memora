import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/usecases/account/create_user_with_email_and_password_usecase.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:memora/application/usecases/account/sign_in_with_email_and_password_usecase.dart';
import 'package:memora/application/usecases/account/sign_out_usecase.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import '../../../helpers/test_exception.dart';

class MockObserveAuthStateChangesUseCase extends Mock
    implements ObserveAuthStateChangesUseCase {}

class MockValidateCurrentUserTokenUseCase extends Mock
    implements ValidateCurrentUserTokenUseCase {}

class MockSendEmailVerificationUseCase extends Mock
    implements SendEmailVerificationUseCase {}

class MockSignInWithEmailAndPasswordUseCase extends Mock
    implements SignInWithEmailAndPasswordUseCase {}

class MockCreateUserWithEmailAndPasswordUseCase extends Mock
    implements CreateUserWithEmailAndPasswordUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockCheckMemberExistsUseCase extends Mock
    implements CheckMemberExistsUseCase {}

class MockCreateMemberFromUserUseCase extends Mock
    implements CreateMemberFromUserUseCase {}

class MockAcceptInvitationUseCase extends Mock
    implements AcceptInvitationUseCase {}

void main() {
  group('AuthNotifier', () {
    late MockObserveAuthStateChangesUseCase mockObserveAuthStateChangesUseCase;
    late MockValidateCurrentUserTokenUseCase
    mockValidateCurrentUserTokenUseCase;
    late MockSendEmailVerificationUseCase mockSendEmailVerificationUseCase;
    late MockSignInWithEmailAndPasswordUseCase
    mockSignInWithEmailAndPasswordUseCase;
    late MockCreateUserWithEmailAndPasswordUseCase
    mockCreateUserWithEmailAndPasswordUseCase;
    late MockSignOutUseCase mockSignOutUseCase;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
    late MockCheckMemberExistsUseCase mockCheckMemberExistsUseCase;
    late MockCreateMemberFromUserUseCase mockCreateMemberFromUserUseCase;
    late MockAcceptInvitationUseCase mockAcceptInvitationUseCase;

    setUp(() {
      mockObserveAuthStateChangesUseCase = MockObserveAuthStateChangesUseCase();
      mockValidateCurrentUserTokenUseCase =
          MockValidateCurrentUserTokenUseCase();
      mockSendEmailVerificationUseCase = MockSendEmailVerificationUseCase();
      mockSignInWithEmailAndPasswordUseCase =
          MockSignInWithEmailAndPasswordUseCase();
      mockCreateUserWithEmailAndPasswordUseCase =
          MockCreateUserWithEmailAndPasswordUseCase();
      mockSignOutUseCase = MockSignOutUseCase();
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      mockCheckMemberExistsUseCase = MockCheckMemberExistsUseCase();
      mockCreateMemberFromUserUseCase = MockCreateMemberFromUserUseCase();
      mockAcceptInvitationUseCase = MockAcceptInvitationUseCase();
    });

    ProviderContainer createContainer(Stream<UserDto?> authStateStream) {
      when(
        mockObserveAuthStateChangesUseCase.execute(),
      ).thenAnswer((_) => authStateStream);

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
          signInWithEmailAndPasswordUseCaseProvider.overrideWithValue(
            mockSignInWithEmailAndPasswordUseCase,
          ),
          createUserWithEmailAndPasswordUseCaseProvider.overrideWithValue(
            mockCreateUserWithEmailAndPasswordUseCase,
          ),
          signOutUseCaseProvider.overrideWithValue(mockSignOutUseCase),
          getCurrentUserUseCaseProvider.overrideWithValue(
            mockGetCurrentUserUseCase,
          ),
          checkMemberExistsUseCaseProvider.overrideWithValue(
            mockCheckMemberExistsUseCase,
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

    test('初期状態はloading', () {
      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);

      expect(state.status, AuthStatus.loading);
      verify(mockObserveAuthStateChangesUseCase.execute()).called(1);
    });

    test('既存メンバーのログイン時にauthenticated状態になる', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockValidateCurrentUserTokenUseCase.execute(),
      ).thenAnswer((_) async {});
      when(
        mockCheckMemberExistsUseCase.execute(user.id),
      ).thenAnswer((_) async => true);

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      expect(notifier.state.status, AuthStatus.authenticated);
      verify(mockCheckMemberExistsUseCase.execute(user.id)).called(1);
    });

    test('新規ユーザーのログイン時にmember_selection_required状態になる', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockValidateCurrentUserTokenUseCase.execute(),
      ).thenAnswer((_) async {});
      when(
        mockCheckMemberExistsUseCase.execute(user.id),
      ).thenAnswer((_) async => false);

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

      when(
        mockValidateCurrentUserTokenUseCase.execute(),
      ).thenAnswer((_) => validateCompleter.future);
      when(
        mockCheckMemberExistsUseCase.execute(user.id),
      ).thenAnswer((_) async => true);

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

      when(
        mockValidateCurrentUserTokenUseCase.execute(),
      ).thenThrow(TestException('token invalid'));
      when(
        mockSignOutUseCase.execute(),
      ).thenAnswer((_) => signOutCompleter.future);

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

      when(
        mockSendEmailVerificationUseCase.execute(),
      ).thenThrow(TestException('send mail failed'));
      when(
        mockSignOutUseCase.execute(),
      ).thenAnswer((_) => signOutCompleter.future);

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
      when(
        mockSignOutUseCase.execute(),
      ).thenAnswer((_) => signOutCompleter.future);

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
      'CheckMemberExistsUseCaseが例外を投げた場合はエラーでサインアウトしunauthenticatedになる',
      () async {
        const user = UserDto(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );

        when(
          mockValidateCurrentUserTokenUseCase.execute(),
        ).thenAnswer((_) async {});
        when(
          mockCheckMemberExistsUseCase.execute(user.id),
        ).thenThrow(TestException('Firestore error'));
        when(mockSignOutUseCase.execute()).thenAnswer((_) async {});

        final controller = StreamController<UserDto?>();
        addTearDown(controller.close);
        final container = createContainer(controller.stream);
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        controller.add(user);
        await Future(() {});

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.message, '認証が無効です。再度ログインしてください。');
        verify(mockSignOutUseCase.execute()).called(1);
      },
    );

    test('createNewMemberが成功した場合authenticated状態になる', () async {
      const userDto = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockCreateMemberFromUserUseCase.execute(userDto),
      ).thenAnswer((_) async => true);
      when(mockGetCurrentUserUseCase.execute()).thenAnswer((_) async => userDto);

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

      when(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).thenAnswer((_) async => true);
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
      verify(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).called(1);
    });

    test('acceptInvitationが失敗した場合falseを返し認証状態は保持される', () async {
      const user = UserDto(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      const invitationCode = 'invalid-code';

      when(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).thenAnswer((_) async => false);

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
      when(mockSignOutUseCase.execute()).thenAnswer((_) async {});

      final controller = StreamController<UserDto?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.loading);
      verify(mockSignOutUseCase.execute()).called(1);
    });
  });
}
