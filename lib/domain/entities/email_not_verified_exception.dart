class EmailNotVerifiedException implements Exception {
  EmailNotVerifiedException([this.message = 'メールアドレスが確認されていません']);

  final String message;

  @override
  String toString() => 'EmailNotVerifiedException: $message';
}
