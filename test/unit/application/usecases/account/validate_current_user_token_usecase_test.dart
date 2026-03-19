import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> validateCurrentUserToken() {
    return super.noSuchMethod(
          Invocation.method(#validateCurrentUserToken, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

void main() {
  group('ValidateCurrentUserTokenUseCase', () {
    late MockAuthService mockAuthService;
    late ValidateCurrentUserTokenUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ValidateCurrentUserTokenUseCase(authService: mockAuthService);
    });

    test('現在ユーザーの認証トークン検証を委譲する', () async {
      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});

      await useCase.execute();

      verify(mockAuthService.validateCurrentUserToken()).called(1);
    });
  });
}
