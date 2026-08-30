import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/account/update_password_usecase.dart';
import 'package:memora/application/services/auth_service.dart';

import 'update_password_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('UpdatePasswordUseCase', () {
    late UpdatePasswordUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = UpdatePasswordUseCase(authService: mockAuthService);
    });

    test('パスワード更新が正常に実行される', () async {
      const newPassword = 'NewPassword123!';
      when(
        mockAuthService.updatePassword(newPassword: newPassword),
      ).thenAnswer((_) async {});

      await expectLater(useCase.execute(newPassword: newPassword), completes);

      verify(
        mockAuthService.updatePassword(newPassword: newPassword),
      ).called(1);
    });
  });
}
