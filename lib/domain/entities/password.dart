class Password {
  final String value;

  Password(String? password) : value = password ?? '' {
    if (password == null || password.isEmpty) {
      throw ArgumentError('パスワードは8文字以上で入力してください');
    }

    if (password.length < 8) {
      throw ArgumentError('パスワードは8文字以上で入力してください');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      throw ArgumentError('パスワードには大文字を含めてください');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      throw ArgumentError('パスワードには小文字を含めてください');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      throw ArgumentError('パスワードには数字を含めてください');
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      throw ArgumentError('パスワードには特殊文字を含めてください');
    }
  }

  static List<String> getRequirements() {
    return ['8文字以上', '大文字を含む', '小文字を含む', '数字を含む', '特殊文字を含む'];
  }

  @override
  String toString() {
    return 'Password(*hidden*)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Password &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
