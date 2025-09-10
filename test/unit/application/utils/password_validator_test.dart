import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    test('有効なパスワードの場合、nullを返す', () {
      const validPassword = 'Password123!';
      final result = PasswordValidator.validate(validPassword);
      expect(result, isNull);
    });

    test('最低8文字未満の場合、エラーメッセージを返す', () {
      const shortPassword = 'Pass1!';
      final result = PasswordValidator.validate(shortPassword);
      expect(result, 'パスワードは8文字以上で入力してください');
    });

    test('大文字が含まれていない場合、エラーメッセージを返す', () {
      const noUppercasePassword = 'password123!';
      final result = PasswordValidator.validate(noUppercasePassword);
      expect(result, 'パスワードには大文字を含めてください');
    });

    test('小文字が含まれていない場合、エラーメッセージを返す', () {
      const noLowercasePassword = 'PASSWORD123!';
      final result = PasswordValidator.validate(noLowercasePassword);
      expect(result, 'パスワードには小文字を含めてください');
    });

    test('数字が含まれていない場合、エラーメッセージを返す', () {
      const noDigitPassword = 'Password!';
      final result = PasswordValidator.validate(noDigitPassword);
      expect(result, 'パスワードには数字を含めてください');
    });

    test('特殊文字が含まれていない場合、エラーメッセージを返す', () {
      const noSpecialCharPassword = 'Password123';
      final result = PasswordValidator.validate(noSpecialCharPassword);
      expect(result, 'パスワードには記号を含めてください');
    });

    test('空文字の場合、最初のエラーメッセージを返す', () {
      const emptyPassword = '';
      final result = PasswordValidator.validate(emptyPassword);
      expect(result, 'パスワードは8文字以上で入力してください');
    });

    test('nullの場合、最初のエラーメッセージを返す', () {
      final result = PasswordValidator.validate(null);
      expect(result, 'パスワードは8文字以上で入力してください');
    });

    test('パスワード要件のリストを返す', () {
      final requirements = PasswordValidator.getPasswordRequirements();
      expect(requirements, hasLength(5));
      expect(requirements, contains('8文字以上'));
      expect(requirements, contains('大文字を含む'));
      expect(requirements, contains('小文字を含む'));
      expect(requirements, contains('数字を含む'));
      expect(requirements, contains('記号を含む (!@#\$%^&*(),.?":{}|<>)'));
    });
  });
}
