import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:memora/core/app_logger.dart';

class DeviceAppLog implements AppLog {
  DeviceAppLog(this._logger);

  final Logger _logger;

  @override
  void i(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    e('エラーが発生しました', error: error, stackTrace: stackTrace);
  }
}

class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (AppLogger.shouldSuppressConsoleOutput(event.origin.error)) return;
    for (final line in event.lines) {
      debugPrint(line);
    }
  }
}

class SilentAppLog implements AppLog {
  const SilentAppLog();

  @override
  void i(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void w(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void e(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {}
}
