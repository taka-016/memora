import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/password.dart';

void main() {
  group('Password値オブジェクトのテスト', () {
    test('有効なパスワードでPasswordインスタンスが作成される', () {
      const validPassword = 'Password123!';
      final password = Password(validPassword);
      expect(password.value, equals(validPassword));
    });

    test('パスワードが空文字の場合、ArgumentErrorが投げられる', () {
      expect(() => Password(''), throwsArgumentError);
    });

    test('パスワードがnullの場合、ArgumentErrorが投げられる', () {
      expect(() => Password(null), throwsArgumentError);
    });

    test('パスワードが8文字未満の場合、ArgumentErrorが投げられる', () {
      expect(() => Password('Pass1!'), throwsArgumentError);
    });

    test('パスワードに大文字が含まれない場合、ArgumentErrorが投げられる', () {
      expect(() => Password('password123!'), throwsArgumentError);
    });

    test('パスワードに小文字が含まれない場合、ArgumentErrorが投げられる', () {
      expect(() => Password('PASSWORD123!'), throwsArgumentError);
    });

    test('パスワードに数字が含まれない場合、ArgumentErrorが投げられる', () {
      expect(() => Password('Password!'), throwsArgumentError);
    });

    test('パスワードに特殊文字が含まれない場合、ArgumentErrorが投げられる', () {
      expect(() => Password('Password123'), throwsArgumentError);
    });

    test('toString()でパスワードが隠蔽される', () {
      final password = Password('Password123!');
      expect(password.toString(), equals('Password(*hidden*)'));
    });

    test('等価性テスト - 同じパスワード値の場合等価', () {
      final password1 = Password('Password123!');
      final password2 = Password('Password123!');
      expect(password1, equals(password2));
    });

    test('等価性テスト - 異なるパスワード値の場合非等価', () {
      final password1 = Password('Password123!');
      final password2 = Password('DifferentPass123!');
      expect(password1, isNot(equals(password2)));
    });

    test('ハッシュコードテスト - 同じパスワード値の場合同じハッシュコード', () {
      final password1 = Password('Password123!');
      final password2 = Password('Password123!');
      expect(password1.hashCode, equals(password2.hashCode));
    });

    test('パスワード要求一覧を取得できる', () {
      final requirements = Password.getRequirements();
      expect(requirements, hasLength(5));
      expect(requirements, contains('8文字以上'));
      expect(requirements, contains('大文字を含む'));
      expect(requirements, contains('小文字を含む'));
      expect(requirements, contains('数字を含む'));
      expect(requirements, contains('特殊文字を含む'));
    });
  });
}
