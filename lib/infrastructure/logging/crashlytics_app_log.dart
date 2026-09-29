import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';
import 'package:memora/infrastructure/logging/device_app_log.dart';

class CrashlyticsAppLog extends DeviceAppLog {
  CrashlyticsAppLog(super.logger, this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) {
    return _crashlytics.recordError(error, stackTrace, fatal: fatal);
  }
}

class CrashlyticsOutput extends LogOutput {
  CrashlyticsOutput(this._crashlytics);
  final FirebaseCrashlytics _crashlytics;

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _crashlytics.log(line);
    }
  }
}
