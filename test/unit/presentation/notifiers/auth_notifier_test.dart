import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import '../../../helpers/test_exception.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([
  AuthService,
  CheckMemberExistsUseCase,
  CreateMemberFromUserUseCase,
  AcceptInvitationUseCase,
])
void main() {
  group('AuthNotifier', () {
    late MockAuthService mockAuthService;
    late MockCheckMemberExistsUseCase mockCheckMemberExistsUseCase;
    late MockCreateMemberFromUserUseCase mockCreateMemberFromUserUseCase;
    late MockAcceptInvitationUseCase mockAcceptInvitationUseCase;

    setUp(() {
      mockAuthService = MockAuthService();
      mockCheckMemberExistsUseCase = MockCheckMemberExistsUseCase();
      mockCreateMemberFromUserUseCase = MockCreateMemberFromUserUseCase();
      mockAcceptInvitationUseCase = MockAcceptInvitationUseCase();
    });

    ProviderContainer createContainer(Stream<User?> authStateStream) {
      when(mockAuthService.authStateChanges).thenAnswer((_) => authStateStream);

      return ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
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
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);

      expect(state.status, AuthStatus.loading);
      verify(mockAuthService.authStateChanges).called(1);
    });

    test('既存メンバーのログイン時にauthenticated状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});
      when(
        mockCheckMemberExistsUseCase.execute(user),
      ).thenAnswer((_) async => true);

      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      expect(notifier.state.status, AuthStatus.authenticated);
      verify(mockCheckMemberExistsUseCase.execute(user)).called(1);
    });

    test('新規ユーザーのログイン時にmember_selection_required状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});
      when(
        mockCheckMemberExistsUseCase.execute(user),
      ).thenAnswer((_) async => false);

      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      controller.add(user);
      await Future(() {});

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.message, 'member_selection_required');
    });

    test(
      'CheckMemberExistsUseCaseが例外を投げた場合はエラーでサインアウトしunauthenticatedになる',
      () async {
        const user = User(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );

        when(
          mockAuthService.validateCurrentUserToken(),
        ).thenAnswer((_) async {});
        when(
          mockCheckMemberExistsUseCase.execute(user),
        ).thenThrow(TestException('Firestore error'));
        when(mockAuthService.signOut()).thenAnswer((_) async {});

        final controller = StreamController<User?>();
        addTearDown(controller.close);
        final container = createContainer(controller.stream);
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        controller.add(user);
        await Future(() {});

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.message, '認証が無効です。再度ログインしてください。');
        verify(mockAuthService.signOut()).called(1);
      },
    );

    test('createNewMemberが成功した場合authenticated状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockCreateMemberFromUserUseCase.execute(user),
      ).thenAnswer((_) async => true);

      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.createNewMember(user);

      expect(notifier.state.status, AuthStatus.authenticated);
      verify(mockCreateMemberFromUserUseCase.execute(user)).called(1);
    });

    test('acceptInvitationが成功した場合authenticated状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      const invitationCode = 'test-code';

      when(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).thenAnswer((_) async => true);

      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.acceptInvitation(invitationCode, user);

      expect(result, true);
      expect(notifier.state.status, AuthStatus.authenticated);
      verify(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).called(1);
    });

    test('acceptInvitationが失敗した場合falseを返し認証状態は保持される', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      const invitationCode = 'invalid-code';

      when(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).thenAnswer((_) async => false);

      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      notifier.state = AuthState.authenticated(user);

      final result = await notifier.acceptInvitation(invitationCode, user);

      expect(result, false);
      expect(notifier.state.status, AuthStatus.authenticated);
    });

    test('ログアウト時はloading状態になる', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      final controller = StreamController<User?>();
      addTearDown(controller.close);
      final container = createContainer(controller.stream);
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.loading);
      verify(mockAuthService.signOut()).called(1);
    });
  });
}
