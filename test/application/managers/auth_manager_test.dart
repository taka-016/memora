import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/auth_state.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:memora/application/managers/auth_manager.dart';

import 'auth_manager_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('AuthManager', () {
    late AuthManager authManager;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authManager = AuthManager(authService: mockAuthService);
    });

    test('初期状態はloading', () {
      expect(authManager.state.status, AuthStatus.loading);
    });

    group('initialize', () {
      test('現在のユーザーが存在する場合、authenticated状態になる', () async {
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'テストユーザー',
          isEmailVerified: true,
        );

        when(mockAuthService.getCurrentUser()).thenAnswer((_) async => user);
        when(mockAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(user));

        await authManager.initialize();

        expect(authManager.state.status, AuthStatus.authenticated);
        expect(authManager.state.user, user);
      });

      test('現在のユーザーが存在しない場合、unauthenticated状態になる', () async {
        when(mockAuthService.getCurrentUser()).thenAnswer((_) async => null);
        when(mockAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        await authManager.initialize();

        expect(authManager.state.status, AuthStatus.unauthenticated);
        expect(authManager.state.user, isNull);
      });
    });

    group('login', () {
      test('正常にログインできる', () async {
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'テストユーザー',
          isEmailVerified: true,
        );

        when(mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => user);

        await authManager.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authManager.state.status, AuthStatus.authenticated);
        expect(authManager.state.user, user);
      });

      test('ログインに失敗した場合、error状態になる', () async {
        when(mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        )).thenThrow(Exception('ログインに失敗しました'));

        await authManager.login(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        expect(authManager.state.status, AuthStatus.error);
        expect(authManager.state.errorMessage, isNotNull);
      });
    });

    group('signup', () {
      test('正常にサインアップできる', () async {
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: null,
          isEmailVerified: false,
        );

        when(mockAuthService.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => user);

        await authManager.signup(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authManager.state.status, AuthStatus.authenticated);
        expect(authManager.state.user, user);
      });

      test('サインアップに失敗した場合、error状態になる', () async {
        when(mockAuthService.createUserWithEmailAndPassword(
          email: 'invalid-email',
          password: 'password123',
        )).thenThrow(Exception('サインアップに失敗しました'));

        await authManager.signup(
          email: 'invalid-email',
          password: 'password123',
        );

        expect(authManager.state.status, AuthStatus.error);
        expect(authManager.state.errorMessage, isNotNull);
      });
    });

    group('logout', () {
      test('正常にログアウトできる', () async {
        when(mockAuthService.signOut()).thenAnswer((_) async => {});

        await authManager.logout();

        expect(authManager.state.status, AuthStatus.unauthenticated);
        expect(authManager.state.user, isNull);
      });

      test('ログアウトに失敗した場合、error状態になる', () async {
        when(mockAuthService.signOut()).thenThrow(Exception('ログアウトに失敗しました'));

        await authManager.logout();

        expect(authManager.state.status, AuthStatus.error);
        expect(authManager.state.errorMessage, isNotNull);
      });
    });

    group('sendPasswordlessSignInLink', () {
      test('正常にパスワードレスサインインリンクを送信できる', () async {
        when(mockAuthService.sendSignInLinkToEmail(
          email: 'test@example.com',
        )).thenAnswer((_) async => {});

        await authManager.sendPasswordlessSignInLink(email: 'test@example.com');

        verify(mockAuthService.sendSignInLinkToEmail(
          email: 'test@example.com',
        )).called(1);
      });

      test('送信に失敗した場合、error状態になる', () async {
        when(mockAuthService.sendSignInLinkToEmail(
          email: 'invalid-email',
        )).thenThrow(Exception('メール送信に失敗しました'));

        await authManager.sendPasswordlessSignInLink(email: 'invalid-email');

        expect(authManager.state.status, AuthStatus.error);
        expect(authManager.state.errorMessage, isNotNull);
      });
    });

    group('signInWithEmailLink', () {
      test('正常にメールリンクでサインインできる', () async {
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'テストユーザー',
          isEmailVerified: true,
        );

        when(mockAuthService.signInWithEmailLink(
          email: 'test@example.com',
          emailLink: 'https://example.com/link',
        )).thenAnswer((_) async => user);

        await authManager.signInWithEmailLink(
          email: 'test@example.com',
          emailLink: 'https://example.com/link',
        );

        expect(authManager.state.status, AuthStatus.authenticated);
        expect(authManager.state.user, user);
      });

      test('サインインに失敗した場合、error状態になる', () async {
        when(mockAuthService.signInWithEmailLink(
          email: 'test@example.com',
          emailLink: 'invalid-link',
        )).thenThrow(Exception('サインインに失敗しました'));

        await authManager.signInWithEmailLink(
          email: 'test@example.com',
          emailLink: 'invalid-link',
        );

        expect(authManager.state.status, AuthStatus.error);
        expect(authManager.state.errorMessage, isNotNull);
      });
    });

    group('clearError', () {
      test('エラー状態をクリアできる', () async {
        when(mockAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        )).thenThrow(Exception('ログインに失敗しました'));

        await authManager.login(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        expect(authManager.state.status, AuthStatus.error);

        authManager.clearError();

        expect(authManager.state.status, AuthStatus.unauthenticated);
        expect(authManager.state.errorMessage, isNull);
      });
    });
  });
}