import 'dart:async';

import 'package:logger/logger.dart' hide ConsoleOutput;
import 'package:memora/core/app_logger.dart' as app_logger;
import 'package:memora/infrastructure/logging/device_app_log.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  app_logger.logger = DeviceAppLog(
    Logger(printer: PrettyPrinter(), output: ConsoleOutput()),
  );
  await testMain();
}
