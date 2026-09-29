import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';

abstract interface class AppServices {
  AppClock get clock;
  AppLog get log;
  Future<void> initialize();
}
