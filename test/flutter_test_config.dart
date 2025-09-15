import 'dart:async';

import 'package:logger/logger.dart';
import 'package:memora/core/app_logger.dart' as app_logger;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // テスト用のloggerを初期化
  app_logger.logger = Logger(
    printer: PrettyPrinter(),
    output: app_logger.ConsoleOutput(),
  );

  await testMain();
}
