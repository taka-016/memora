import 'package:memora/core/app_logger.dart';

class TestException implements ConsoleLogSuppressedException {
  final String message;

  TestException([this.message = 'テストエラー']);

  @override
  String toString() => 'TestException: $message';
}
