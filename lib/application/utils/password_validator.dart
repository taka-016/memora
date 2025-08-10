class PasswordValidator {
  static const String _specialCharacters = '!@#\$%^&*(),.?":{}|<>';

  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'パスワードは8文字以上で入力してください';
    }

    if (password.length < 8) {
      return 'パスワードは8文字以上で入力してください';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'パスワードには大文字を含めてください';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'パスワードには小文字を含めてください';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'パスワードには数字を含めてください';
    }

    if (!RegExp('[${RegExp.escape(_specialCharacters)}]').hasMatch(password)) {
      return 'パスワードには記号を含めてください';
    }

    return null;
  }

  static List<String> getPasswordRequirements() {
    return [
      '8文字以上',
      '大文字を含む',
      '小文字を含む',
      '数字を含む',
      '記号を含む ($_specialCharacters)',
    ];
  }
}
