import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/update_email_usecase.dart';
import 'package:memora/application/interfaces/auth_service.dart';

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

    test('メールアドレス更新でエラーが発生した場合は例外を再スローする', () async {
      const newEmail = 'new@example.com';
      const errorMessage = 'メールアドレス更新エラー';
      when(
        mockAuthService.updateEmail(newEmail: newEmail),
      ).thenThrow(Exception(errorMessage));

      await expectLater(
        useCase.execute(newEmail: newEmail),
        throwsA(isA<Exception>()),
      );

      verify(mockAuthService.updateEmail(newEmail: newEmail)).called(1);
    });
  });
}
