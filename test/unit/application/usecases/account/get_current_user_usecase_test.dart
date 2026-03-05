import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<User?> getCurrentUser() {
    return super.noSuchMethod(
          Invocation.method(#getCurrentUser, []),
          returnValue: Future<User?>.value(),
          returnValueForMissingStub: Future<User?>.value(),
        )
        as Future<User?>;
  }
}

void main() {
  group('GetCurrentUserUseCase', () {
    late MockAuthService mockAuthService;
    late GetCurrentUserUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = GetCurrentUserUseCase(authService: mockAuthService);
    });

    test('ログイン中ユーザーを取得できる', () async {
      const expectedUser = User(
        id: 'user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      when(
        mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => expectedUser);

      final actual = await useCase.execute();

      expect(actual, expectedUser);
      verify(mockAuthService.getCurrentUser()).called(1);
    });

    test('未ログイン時はnullを返す', () async {
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

      final actual = await useCase.execute();

      expect(actual, isNull);
      verify(mockAuthService.getCurrentUser()).called(1);
    });

    test('取得時にエラーが発生した場合は例外を再スローする', () async {
      when(
        mockAuthService.getCurrentUser(),
      ).thenThrow(TestException('ユーザー取得失敗'));

      await expectLater(useCase.execute(), throwsA(isA<TestException>()));
      verify(mockAuthService.getCurrentUser()).called(1);
    });
  });
}
