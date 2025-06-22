import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/services/auth_service.dart';
import 'package:memora/application/usecases/logout_usecase.dart';

import 'logout_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('LogoutUsecase', () {
    late LogoutUsecase logoutUsecase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      logoutUsecase = LogoutUsecase(authService: mockAuthService);
    });

    test('正常にログアウトできる', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async => {});

      await logoutUsecase.execute();

      verify(mockAuthService.signOut()).called(1);
    });

    test('ログアウトに失敗した場合、例外を投げる', () async {
      when(mockAuthService.signOut()).thenThrow(Exception('ログアウトに失敗しました'));

      expect(() => logoutUsecase.execute(), throwsException);
    });
  });
}
