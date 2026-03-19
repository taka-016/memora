import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/signup_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'signup_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('SignupUseCase', () {
    late SignupUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SignupUseCase(authService: mockAuthService);
    });

    test('サインアップが正常に実行される', () async {
      const email = 'test@example.com';
      const password = 'Password123!';
      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async {});

      await expectLater(
        useCase.execute(email: email, password: password),
        completes,
      );

      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });

    test('サインアップでエラーが発生した場合は例外を再スローする', () async {
      const email = 'test@example.com';
      const password = 'Password123!';
      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenThrow(TestException('サインアップエラー'));

      await expectLater(
        useCase.execute(email: email, password: password),
        throwsA(isA<TestException>()),
      );

      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });
}
