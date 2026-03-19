import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> sendEmailVerification() {
    return super.noSuchMethod(
          Invocation.method(#sendEmailVerification, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

void main() {
  group('SendEmailVerificationUseCase', () {
    late MockAuthService mockAuthService;
    late SendEmailVerificationUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SendEmailVerificationUseCase(authService: mockAuthService);
    });

    test('認証メール送信を委譲する', () async {
      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});

      await useCase.execute();

      verify(mockAuthService.sendEmailVerification()).called(1);
    });
  });
}
