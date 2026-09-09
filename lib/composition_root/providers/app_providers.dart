import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/time/ntp_synchronized_app_clock.dart';
import 'package:memora/infrastructure/time/system_app_clock.dart';

final appCapabilitiesProvider = Provider<AppCapabilities>((ref) {
  return AppCapabilities.forMode(ref.watch(appModeProvider));
});

final appClockProvider = Provider<AppClock>((ref) {
  return switch (ref.watch(appModeProvider)) {
    AppMode.online => NtpSynchronizedAppClock(),
    AppMode.offline => const SystemAppClock(),
  };
});
