import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/reauthenticate_usecase.dart';
import 'package:memora/domain/services/auth/auth_service.dart';

import 'reauthenticate_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('ReauthenticateUseCase', () {
    late ReauthenticateUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ReauthenticateUseCase(authService: mockAuthService);
    });

    test('再認証が正常に実行される', () async {
      const password = 'CurrentPassword123!';
      when(
        mockAuthService.reauthenticate(password: password),
      ).thenAnswer((_) async {});

      await expectLater(useCase.execute(password: password), completes);

      verify(mockAuthService.reauthenticate(password: password)).called(1);
    });

    test('再認証でエラーが発生した場合は例外を再スローする', () async {
      const password = 'WrongPassword';
      const errorMessage = '再認証エラー';
      when(
        mockAuthService.reauthenticate(password: password),
      ).thenThrow(Exception(errorMessage));

      await expectLater(
        useCase.execute(password: password),
        throwsA(isA<Exception>()),
      );

      verify(mockAuthService.reauthenticate(password: password)).called(1);
    });
  });
}
