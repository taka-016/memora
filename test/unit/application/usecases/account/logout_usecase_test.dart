import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'logout_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = LogoutUseCase(authService: mockAuthService);
    });

    test('ログアウトが正常に実行される', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await expectLater(useCase.execute(), completes);

      verify(mockAuthService.signOut()).called(1);
    });

    test('ログアウトでエラーが発生した場合は例外を再スローする', () async {
      when(mockAuthService.signOut()).thenThrow(TestException('ログアウトエラー'));

      await expectLater(useCase.execute(), throwsA(isA<TestException>()));

      verify(mockAuthService.signOut()).called(1);
    });
  });
}
