late AppLog logger;

abstract interface class AppLog {
  void i(String message, {Object? error, StackTrace? stackTrace});
  void w(String message, {Object? error, StackTrace? stackTrace});
  void e(String message, {Object? error, StackTrace? stackTrace});
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  });
}

abstract interface class ConsoleLogSuppressedException implements Exception {}

class AppLogger {
  static bool _suppressLogging = false;

  static void suppressLogging(bool suppress) {
    _suppressLogging = suppress;
  }

  static bool get isLoggingSuppressed => _suppressLogging;

  static bool shouldSuppressConsoleOutput(Object? error) {
    if (_suppressLogging) {
      _suppressLogging = false;
      return true;
    }
    return error is ConsoleLogSuppressedException;
  }
}
