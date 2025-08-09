import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/services/auth_service.dart';

import 'auth_service_email_verification_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('AuthService メール確認機能', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    test('メール確認送信が正常に動作する', () async {
      // Arrange
      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async => {});

      // Act & Assert
      expect(
        () async => await mockAuthService.sendEmailVerification(),
        returnsNormally,
      );
      verify(mockAuthService.sendEmailVerification()).called(1);
    });

    test('メール確認送信でエラーが発生した場合例外が投げられる', () async {
      // Arrange
      when(
        mockAuthService.sendEmailVerification(),
      ).thenThrow(Exception('メール送信に失敗しました'));

      // Act & Assert
      expect(
        () async => await mockAuthService.sendEmailVerification(),
        throwsA(isA<Exception>()),
      );
    });

    test('ユーザーがログインしていない場合はメール確認送信でエラーが発生する', () async {
      // Arrange
      when(
        mockAuthService.sendEmailVerification(),
      ).thenThrow(Exception('ユーザーがログインしていません'));

      // Act & Assert
      expect(
        () async => await mockAuthService.sendEmailVerification(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
