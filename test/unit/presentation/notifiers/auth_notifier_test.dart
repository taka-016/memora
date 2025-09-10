import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/application/usecases/member/get_or_create_member_usecase.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([AuthService, GetOrCreateMemberUseCase])
void main() {
  group('AuthNotifier', () {
    late AuthNotifier authNotifier;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authNotifier = AuthNotifier(authService: mockAuthService);
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

    test('ユーザーログイン時にauthenticated状態になる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      await authNotifier.initialize();

      // act
      controller.add(user);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      expect(authNotifier.state.status, AuthStatus.authenticated);
      expect(authNotifier.state.user, user);

      controller.close();
    });

    test('ユーザーログアウト時にunauthenticated状態になる', () async {
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      await authNotifier.initialize();

      // act
      controller.add(null);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.user, isNull);

      controller.close();
    });

    test('authStateChanges経由でメンバー取得・作成処理が実行される', () async {
      // arrange
      late MockGetOrCreateMemberUseCase mockGetOrCreateMemberUseCase;
      mockGetOrCreateMemberUseCase = MockGetOrCreateMemberUseCase();

      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      // authStateChangesでユーザー状態変更をシミュレート
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => user);
      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});

      when(
        mockGetOrCreateMemberUseCase.execute(user),
      ).thenAnswer((_) async => true);

      // AuthNotifierにUseCaseを依存注入
      authNotifier = AuthNotifier(
        authService: mockAuthService,
        getOrCreateMemberUseCase: mockGetOrCreateMemberUseCase,
      );

      await authNotifier.initialize();

      // act - authStateChangesでユーザー変更をエミット
      controller.add(user);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      verify(mockGetOrCreateMemberUseCase.execute(user)).called(1);

      controller.close();
    });

    test('認証エラー時に強制ログアウトしてerror状態になる', () async {
      // arrange
      late MockGetOrCreateMemberUseCase mockGetOrCreateMemberUseCase;
      mockGetOrCreateMemberUseCase = MockGetOrCreateMemberUseCase();

      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      // authStateChangesでユーザー状態変更をシミュレート
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      // validateCurrentUserToken()で認証エラーをシミュレート
      when(
        mockAuthService.validateCurrentUserToken(),
      ).thenThrow(Exception('認証トークンが無効です'));
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      // AuthNotifierにUseCaseを依存注入
      authNotifier = AuthNotifier(
        authService: mockAuthService,
        getOrCreateMemberUseCase: mockGetOrCreateMemberUseCase,
      );

      await authNotifier.initialize();

      // act - authStateChangesでユーザー変更をエミット
      controller.add(user);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      verify(mockAuthService.signOut()).called(1);
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, '認証が無効です。再度ログインしてください。');

      controller.close();
    });

    test('メール認証が未完了の場合、強制ログアウトしてerror状態になる', () async {
      // arrange
      const unverifiedUser = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: false,
      );

      // authStateChangesでユーザー状態変更をシミュレート
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      when(mockAuthService.signOut()).thenAnswer((_) async {});
      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});

      await authNotifier.initialize();

      // act - authStateChangesでメール未認証ユーザーをエミット
      controller.add(unverifiedUser);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      verify(mockAuthService.sendEmailVerification()).called(1);
      verify(mockAuthService.signOut()).called(1);
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, '認証メールを再送しました。メールを確認して認証を完了してください。');

      // act - ログアウト後にnullユーザーをエミット（signOutの結果）
      controller.add(null);
      await Future(() {});

      // assert - エラー状態が保持されることを確認
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, '認証メールを再送しました。メールを確認して認証を完了してください。');

      controller.close();
    });

    test('メール認証が未完了でメール再送に失敗した場合、通常のエラーメッセージが表示される', () async {
      // arrange
      const unverifiedUser = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: false,
      );

      // authStateChangesでユーザー状態変更をシミュレート
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      when(mockAuthService.signOut()).thenAnswer((_) async {});
      when(
        mockAuthService.sendEmailVerification(),
      ).thenThrow(Exception('メール送信失敗'));

      await authNotifier.initialize();

      // act - authStateChangesでメール未認証ユーザーをエミット
      controller.add(unverifiedUser);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      verify(mockAuthService.sendEmailVerification()).called(1);
      verify(mockAuthService.signOut()).called(1);
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, '認証メールの送信に失敗しました。再度ログインしてください。');

      controller.close();
    });

    test('GetOrCreateMemberUseCaseがfalseを返した場合、強制ログアウトしてerror状態になる', () async {
      // arrange
      late MockGetOrCreateMemberUseCase mockGetOrCreateMemberUseCase;
      mockGetOrCreateMemberUseCase = MockGetOrCreateMemberUseCase();

      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      // authStateChangesでユーザー状態変更をシミュレート
      final controller = StreamController<User?>();
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});

      // GetOrCreateMemberUseCaseがfalseを返すようにモック
      when(
        mockGetOrCreateMemberUseCase.execute(user),
      ).thenAnswer((_) async => false);

      when(mockAuthService.signOut()).thenAnswer((_) async {});

      // AuthNotifierにUseCaseを依存注入
      authNotifier = AuthNotifier(
        authService: mockAuthService,
        getOrCreateMemberUseCase: mockGetOrCreateMemberUseCase,
      );

      await authNotifier.initialize();

      // act - authStateChangesでユーザー変更をエミット
      controller.add(user);

      // authStateChangesリスナー内の非同期処理完了を待つ
      await Future(() {});

      // assert
      verify(mockGetOrCreateMemberUseCase.execute(user)).called(1);
      verify(mockAuthService.signOut()).called(1);
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, '認証が無効です。再度ログインしてください。');

      controller.close();
    });

    test('正常にログインできる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      when(
        mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => user);

      await authNotifier.login(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(
        mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('ログインに失敗した場合、error状態になる', () async {
      when(
        mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(Exception('ログインに失敗しました'));

      await authNotifier.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, isNotNull);
    });

    test('正常にサインアップできる', () async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: null,
        isVerified: false,
      );

      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => user);
      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});

      await authNotifier.signup(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('サインアップに失敗した場合、error状態になる', () async {
      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: 'invalid-email',
          password: 'password123',
        ),
      ).thenThrow(Exception('サインアップに失敗しました'));

      await authNotifier.signup(
        email: 'invalid-email',
        password: 'password123',
      );

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, isNotNull);
    });

    test('正常にログアウトできる', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async => {});

      await authNotifier.logout();

      verify(mockAuthService.signOut()).called(1);
    });

    test('エラー状態をクリアできる', () async {
      when(
        mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(Exception('ログインに失敗しました'));

      await authNotifier.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(authNotifier.state.status, AuthStatus.unauthenticated);

      authNotifier.clearError();

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.message, isEmpty);
    });
  });
}
