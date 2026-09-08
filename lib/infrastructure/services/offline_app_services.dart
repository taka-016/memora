import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' hide ConsoleOutput;
import 'package:memora/application/services/app_services.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/logging/device_app_log.dart';
import 'package:memora/infrastructure/time/system_app_clock.dart';

class OfflineAppServices implements AppServices {
  @override
  final AppClock clock = const SystemAppClock();

  @override
  final AppLog log = kDebugMode
      ? DeviceAppLog(Logger(printer: PrettyPrinter(), output: ConsoleOutput()))
      : const SilentAppLog();

  @override
  Future<void> initialize() async {}
}
