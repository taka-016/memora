import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/sign_in_with_email_and_password_usecase.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return super.noSuchMethod(
          Invocation.method(#signInWithEmailAndPassword, [], {
            #email: email,
            #password: password,
          }),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

void main() {
  group('SignInWithEmailAndPasswordUseCase', () {
    late MockAuthService mockAuthService;
    late SignInWithEmailAndPasswordUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SignInWithEmailAndPasswordUseCase(authService: mockAuthService);
    });

    test('メールアドレス認証ログインを委譲する', () async {
      const email = 'test@example.com';
      const password = 'Password123!';
      when(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async {});

      await useCase.execute(email: email, password: password);

      verify(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });
}
