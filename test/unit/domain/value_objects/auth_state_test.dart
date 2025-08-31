import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/domain/entities/user.dart';

void main() {
  group('AuthState', () {
    test('初期状態はloading', () {
      const authState = AuthState.loading();
      expect(authState.status, AuthStatus.loading);
      expect(authState.user, isNull);
      expect(authState.message, isEmpty);
    });

    test('認証済み状態を正常に作成できる', () {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      const authState = AuthState.authenticated(user);
      expect(authState.status, AuthStatus.authenticated);
      expect(authState.user, user);
      expect(authState.message, isEmpty);
    });

    test('未認証状態を正常に作成できる', () {
      final authState = AuthState.unauthenticated('');
      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.user, isNull);
      expect(authState.message, isEmpty);
      expect(authState.messageType, MessageType.info);
    });

    test('エラー状態を正常に作成できる', () {
      const message = 'ログインに失敗しました';
      const authState = AuthState.unauthenticated(
        message,
        messageType: MessageType.error,
      );
      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.user, isNull);
      expect(authState.message, message);
      expect(authState.messageType, MessageType.error);
    });

    test('isAuthenticated ゲッターが正しく動作する', () {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      const authenticatedState = AuthState.authenticated(user);
      final unauthenticatedState = AuthState.unauthenticated('');
      const loadingState = AuthState.loading();

      expect(authenticatedState.isAuthenticated, true);
      expect(unauthenticatedState.isAuthenticated, false);
      expect(loadingState.isAuthenticated, false);
    });

    test('等価性の比較ができる', () {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      const state1 = AuthState.authenticated(user);
      const state2 = AuthState.authenticated(user);
      final state3 = AuthState.unauthenticated('');

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
