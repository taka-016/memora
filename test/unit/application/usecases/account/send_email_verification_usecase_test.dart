import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'send_email_verification_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('SendEmailVerificationUseCase', () {
    late SendEmailVerificationUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SendEmailVerificationUseCase(authService: mockAuthService);
    });

    test('認証メール送信が正常に実行される', () async {
      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});

      await expectLater(useCase.execute(), completes);

      verify(mockAuthService.sendEmailVerification()).called(1);
    });
  });
}
