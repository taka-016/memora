import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/sign_out_usecase.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> signOut() {
    return super.noSuchMethod(
          Invocation.method(#signOut, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

void main() {
  group('SignOutUseCase', () {
    late MockAuthService mockAuthService;
    late SignOutUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SignOutUseCase(authService: mockAuthService);
    });

    test('ログアウトを委譲する', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await useCase.execute();

      verify(mockAuthService.signOut()).called(1);
    });
  });
}
