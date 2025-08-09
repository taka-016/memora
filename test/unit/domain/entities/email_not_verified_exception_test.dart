import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/email_not_verified_exception.dart';

void main() {
  group('EmailNotVerifiedException', () {
    test('メッセージ付きでEmailNotVerifiedExceptionを作成できる', () {
      const message = 'メールアドレスが確認されていません';
      final exception = EmailNotVerifiedException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(), contains(message));
    });

    test('デフォルトメッセージでEmailNotVerifiedExceptionを作成できる', () {
      final exception = EmailNotVerifiedException();

      expect(exception.message, equals('メールアドレスが確認されていません'));
      expect(exception.toString(), contains('メールアドレスが確認されていません'));
    });
  });
}
