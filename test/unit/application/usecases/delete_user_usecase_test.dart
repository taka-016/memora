import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/delete_user_usecase.dart';
import 'package:memora/domain/services/auth/auth_service.dart';

import 'delete_user_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('DeleteUserUseCase', () {
    late DeleteUserUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = DeleteUserUseCase(authService: mockAuthService);
    });

    test('アカウント削除が正常に実行される', () async {
      when(mockAuthService.deleteUser()).thenAnswer((_) async {});

      await expectLater(useCase.execute(), completes);

      verify(mockAuthService.deleteUser()).called(1);
    });

    test('アカウント削除でエラーが発生した場合は例外を再スローする', () async {
      const errorMessage = 'アカウント削除エラー';
      when(mockAuthService.deleteUser()).thenThrow(Exception(errorMessage));

      await expectLater(useCase.execute(), throwsA(isA<Exception>()));

      verify(mockAuthService.deleteUser()).called(1);
    });
  });
}
