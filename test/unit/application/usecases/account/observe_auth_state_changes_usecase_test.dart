import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Stream<User?> get authStateChanges {
    return super.noSuchMethod(
          Invocation.getter(#authStateChanges),
          returnValue: const Stream<User?>.empty(),
          returnValueForMissingStub: const Stream<User?>.empty(),
        )
        as Stream<User?>;
  }
}

void main() {
  group('ObserveAuthStateChangesUseCase', () {
    late MockAuthService mockAuthService;
    late ObserveAuthStateChangesUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ObserveAuthStateChangesUseCase(authService: mockAuthService);
    });

    test('認証ユーザーをUserDtoへ変換して流す', () async {
      const user = User(
        id: 'user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream<User?>.value(user));

      await expectLater(
        useCase.execute(),
        emits(
          const UserDto(
            id: 'user-id',
            loginId: 'test@example.com',
            isVerified: true,
          ),
        ),
      );
    });

    test('未認証時はnullをそのまま流す', () async {
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream<User?>.value(null));

      await expectLater(useCase.execute(), emits(null));
    });
  });
}
