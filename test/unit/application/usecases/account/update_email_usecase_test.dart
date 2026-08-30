import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/account/update_email_usecase.dart';
import 'package:memora/application/services/auth_service.dart';

import 'update_email_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('UpdateEmailUseCase', () {
    late UpdateEmailUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = UpdateEmailUseCase(authService: mockAuthService);
    });

    test('メールアドレス更新が正常に実行される', () async {
      const newEmail = 'new@example.com';
      when(
        mockAuthService.updateEmail(newEmail: newEmail),
      ).thenAnswer((_) async {});

      await expectLater(useCase.execute(newEmail: newEmail), completes);

      verify(mockAuthService.updateEmail(newEmail: newEmail)).called(1);
    });
  });
}
