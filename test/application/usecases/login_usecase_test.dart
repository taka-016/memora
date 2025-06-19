import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:memora/application/usecases/login_usecase.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('LoginUsecase', () {
    late LoginUsecase loginUsecase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      loginUsecase = LoginUsecase(authService: mockAuthService);
    });

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

      final result = await loginUsecase.execute(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, user);
      verify(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('ログインに失敗した場合、例外を投げる', () async {
      when(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(Exception('ログインに失敗しました'));

      expect(
        () => loginUsecase.execute(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
        throwsException,
      );
    });
  });
}