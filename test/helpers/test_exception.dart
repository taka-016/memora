class TestException implements Exception {
  final String message;

  const TestException([this.message = 'テストエラー']);

  @override
  String toString() => 'TestException: $message';
}
