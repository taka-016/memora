import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([AuthService])

void main() {
  group('AuthService インターフェース', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    test('getCurrentUserメソッドが存在する', () async {
      const user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => user);

      final result = await mockAuthService.getCurrentUser();
      expect(result, user);
      verify(mockAuthService.getCurrentUser()).called(1);
    });

    test('signInWithEmailAndPasswordメソッドが存在する', () async {
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

      final result = await mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, user);
      verify(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('createUserWithEmailAndPasswordメソッドが存在する', () async {
      const user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: false,
      );

      when(mockAuthService.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => user);

      final result = await mockAuthService.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, user);
      verify(mockAuthService.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('signOutメソッドが存在する', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async => {});

      await mockAuthService.signOut();
      verify(mockAuthService.signOut()).called(1);
    });

    test('sendSignInLinkToEmailメソッドが存在する', () async {
      when(mockAuthService.sendSignInLinkToEmail(
        email: 'test@example.com',
      )).thenAnswer((_) async => {});

      await mockAuthService.sendSignInLinkToEmail(email: 'test@example.com');
      verify(mockAuthService.sendSignInLinkToEmail(
        email: 'test@example.com',
      )).called(1);
    });

    test('signInWithEmailLinkメソッドが存在する', () async {
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

      final result = await mockAuthService.signInWithEmailLink(
        email: 'test@example.com',
        emailLink: 'https://example.com/link',
      );

      expect(result, user);
      verify(mockAuthService.signInWithEmailLink(
        email: 'test@example.com',
        emailLink: 'https://example.com/link',
      )).called(1);
    });

    test('authStateChangesストリームが存在する', () {
      const user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(user));

      final stream = mockAuthService.authStateChanges;
      expect(stream, isA<Stream<User?>>());
    });
  });
}