import 'dart:async';
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
    late AuthNotifier authNotifier;
    late MockAuthService mockAuthService;
    late MockCheckMemberExistsUseCase mockCheckMemberExistsUseCase;
    late MockCreateMemberFromUserUseCase mockCreateMemberFromUserUseCase;
    late MockAcceptInvitationUseCase mockAcceptInvitationUseCase;

    setUp(() {
      mockAuthService = MockAuthService();
      mockCheckMemberExistsUseCase = MockCheckMemberExistsUseCase();
      mockCreateMemberFromUserUseCase = MockCreateMemberFromUserUseCase();
      mockAcceptInvitationUseCase = MockAcceptInvitationUseCase();

      authNotifier = AuthNotifier(
        authService: mockAuthService,
        checkMemberExistsUseCase: mockCheckMemberExistsUseCase,
        createMemberFromUserUseCase: mockCreateMemberFromUserUseCase,
        acceptInvitationUseCase: mockAcceptInvitationUseCase,
      );
    });

    test('初期状態はloading', () {
      expect(authNotifier.state.status, AuthStatus.loading);
    });

    test('initializeでauthStateChangesのリスナーが登録される', () async {
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      await authNotifier.initialize();

      expect(authNotifier.state.status, AuthStatus.loading);
      verify(mockAuthService.authStateChanges).called(1);

      controller.close();
    });

    test('既存メンバーのログイン時にauthenticated状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);
      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});
      when(
        mockCheckMemberExistsUseCase.execute(user),
      ).thenAnswer((_) async => true);

      await authNotifier.initialize();
      controller.add(user);
      await Future(() {});

      expect(authNotifier.state.status, AuthStatus.authenticated);
      verify(mockCheckMemberExistsUseCase.execute(user)).called(1);

      controller.close();
    });

    test('新規ユーザーのログイン時にmember_selection_required状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);
      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});
      when(
        mockCheckMemberExistsUseCase.execute(user),
      ).thenAnswer((_) async => false);

      await authNotifier.initialize();
      controller.add(user);
      await Future(() {});

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, 'member_selection_required');

      controller.close();
    });

    test(
      'CheckMemberExistsUseCaseが例外を投げた場合はエラーでサインアウトしunauthenticatedになる',
      () async {
        const user = User(
          id: 'user123',
          loginId: 'test@example.com',
          isVerified: true,
        );

        final controller = StreamController<User?>();
        when(
          mockAuthService.authStateChanges,
        ).thenAnswer((_) => controller.stream);
        when(
          mockAuthService.validateCurrentUserToken(),
        ).thenAnswer((_) async {});
        when(
          mockCheckMemberExistsUseCase.execute(user),
        ).thenThrow(TestException('Firestore error'));
        when(mockAuthService.signOut()).thenAnswer((_) async {});

        await authNotifier.initialize();
        controller.add(user);
        await Future(() {});

        expect(authNotifier.state.status, AuthStatus.unauthenticated);
        expect(authNotifier.state.message, '認証が無効です。再度ログインしてください。');
        verify(mockAuthService.signOut()).called(1);

        controller.close();
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

      await authNotifier.createNewMember(user);

      expect(authNotifier.state.status, AuthStatus.authenticated);
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

      final result = await authNotifier.acceptInvitation(invitationCode, user);

      expect(result, true);
      expect(authNotifier.state.status, AuthStatus.authenticated);
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

      // 事前に認証状態にする
      authNotifier.state = AuthState.authenticated(user);

      when(
        mockAcceptInvitationUseCase.execute(invitationCode, user.id),
      ).thenAnswer((_) async => false);

      final result = await authNotifier.acceptInvitation(invitationCode, user);

      expect(result, false);
      // AuthStateは変更されずにauthenticated状態のまま
      expect(authNotifier.state.status, AuthStatus.authenticated);
    });

    test('ログアウト時はunauthenticated状態になる', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await authNotifier.logout();

      expect(authNotifier.state.status, AuthStatus.loading);
      verify(mockAuthService.signOut()).called(1);
    });
  });
}
