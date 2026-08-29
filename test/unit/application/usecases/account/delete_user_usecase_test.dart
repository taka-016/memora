import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/account/delete_user_usecase.dart';
import 'package:memora/application/services/auth_service.dart';

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
  });
}
