import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/signup_usecase.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:memora/domain/entities/user.dart';

import 'signup_usecase_email_verification_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('SignupUsecase メール確認機能', () {
    late SignupUsecase signupUsecase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      signupUsecase = SignupUsecase(authService: mockAuthService);
    });

    test('サインアップ成功後にメール確認が送信される', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'TestPass123!';
      final user = User(
        id: 'user123',
        loginId: email,
        displayName: null,
        isVerified: false,
      );

      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => user);

      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async => {});

      // Act
      final result = await signupUsecase.execute(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(user));
      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
      verify(mockAuthService.sendEmailVerification()).called(1);
    });

    test('ユーザー作成に失敗した場合はメール確認は送信されない', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'TestPass123!';

      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenThrow(Exception('ユーザー作成に失敗しました'));

      // Act & Assert
      expect(
        () async =>
            await signupUsecase.execute(email: email, password: password),
        throwsA(isA<Exception>()),
      );

      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
      verifyNever(mockAuthService.sendEmailVerification());
    });

    test('メール確認送信に失敗してもユーザー作成は完了する', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'TestPass123!';
      final user = User(
        id: 'user123',
        loginId: email,
        displayName: null,
        isVerified: false,
      );

      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => user);

      when(
        mockAuthService.sendEmailVerification(),
      ).thenThrow(Exception('メール送信に失敗しました'));

      // Act
      final result = await signupUsecase.execute(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(user));
      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
      verify(mockAuthService.sendEmailVerification()).called(1);
    });
  });
}
