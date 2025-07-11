import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:memora/application/usecases/signup_usecase.dart';

import 'signup_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('SignupUsecase', () {
    late SignupUsecase signupUsecase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      signupUsecase = SignupUsecase(authService: mockAuthService);
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

      final result = await signupUsecase.execute(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, user);
      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('サインアップに失敗した場合、例外を投げる', () async {
      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: 'invalid-email',
          password: 'password123',
        ),
      ).thenThrow(Exception('サインアップに失敗しました'));

      expect(
        () => signupUsecase.execute(
          email: 'invalid-email',
          password: 'password123',
        ),
        throwsException,
      );
    });
  });
}
