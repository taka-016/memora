import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'validate_current_user_token_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('ValidateCurrentUserTokenUseCase', () {
    late ValidateCurrentUserTokenUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ValidateCurrentUserTokenUseCase(authService: mockAuthService);
    });

    test('現在のユーザートークン検証が正常に実行される', () async {
      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});

      await expectLater(useCase.execute(), completes);

      verify(mockAuthService.validateCurrentUserToken()).called(1);
    });
  });
}
