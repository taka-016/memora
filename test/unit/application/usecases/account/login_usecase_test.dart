import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = LoginUseCase(authService: mockAuthService);
    });

    test('ログインが正常に実行される', () async {
      const email = 'test@example.com';
      const password = 'Password123!';
      when(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async {});

      await expectLater(
        useCase.execute(email: email, password: password),
        completes,
      );

      verify(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });
}
