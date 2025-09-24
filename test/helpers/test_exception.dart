import 'package:memora/core/app_logger.dart';

class TestException implements Exception {
  final String message;

  TestException([this.message = 'テストエラー']) {
    AppLogger.suppressLogging(true);
  }

  @override
  String toString() => 'TestException: $message';
}
