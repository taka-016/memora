import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/login_usecase.dart';
import 'package:memora/domain/entities/email_not_verified_exception.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AuthService])
import 'login_usecase_email_verification_test.mocks.dart';

void main() {
  group('LoginUsecase メール確認チェック', () {
    late MockAuthService mockAuthService;
    late LoginUsecase loginUsecase;

    setUp(() {
      mockAuthService = MockAuthService();
      loginUsecase = LoginUsecase(authService: mockAuthService);
    });

    test('メール確認済みユーザーはログインが成功する', () async {
      const email = 'test@example.com';
      const password = 'password';
      final verifiedUser = User(
        id: 'user123',
        loginId: email,
        displayName: 'Test User',
        isVerified: true,
      );

      when(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => verifiedUser);

      final result = await loginUsecase.execute(
        email: email,
        password: password,
      );

      expect(result, equals(verifiedUser));
      verify(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });

    test('メール未確認ユーザーはEmailNotVerifiedExceptionが発生する', () async {
      const email = 'test@example.com';
      const password = 'password';
      final unverifiedUser = User(
        id: 'user123',
        loginId: email,
        displayName: 'Test User',
        isVerified: false,
      );

      when(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => unverifiedUser);

      expect(
        () async =>
            await loginUsecase.execute(email: email, password: password),
        throwsA(isA<EmailNotVerifiedException>()),
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
