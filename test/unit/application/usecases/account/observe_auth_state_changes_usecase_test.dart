import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'observe_auth_state_changes_usecase_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('ObserveAuthStateChangesUseCase', () {
    late ObserveAuthStateChangesUseCase useCase;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ObserveAuthStateChangesUseCase(authService: mockAuthService);
    });

    test('認証状態の変更をUserDtoへ変換して返す', () async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      final stream = useCase.execute();

      controller
        ..add(
          const User(
            id: 'user-id',
            loginId: 'test@example.com',
            displayName: 'テストユーザー',
            isVerified: true,
          ),
        )
        ..add(null);

      await expectLater(
        stream,
        emitsInOrder([
          const UserDto(
            id: 'user-id',
            loginId: 'test@example.com',
            displayName: 'テストユーザー',
            isVerified: true,
          ),
          null,
        ]),
      );
    });

    test('認証状態ストリームのエラーをそのまま伝播する', () async {
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      final stream = useCase.execute();
      final error = TestException('認証状態監視エラー');

      controller.addError(error);

      await expectLater(stream, emitsError(isA<TestException>()));
    });
  });
}
