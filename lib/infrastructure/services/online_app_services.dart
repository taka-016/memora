import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' hide ConsoleOutput;
import 'package:memora/application/services/app_services.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/firebase_options.dart';
import 'package:memora/infrastructure/logging/crashlytics_app_log.dart';
import 'package:memora/infrastructure/logging/device_app_log.dart';
import 'package:memora/infrastructure/time/ntp_synchronized_app_clock.dart';

class OnlineAppServices implements AppServices {
  @override
  final AppClock clock = NtpSynchronizedAppClock();

  @override
  AppLog log = kDebugMode
      ? DeviceAppLog(Logger(printer: PrettyPrinter(), output: ConsoleOutput()))
      : const SilentAppLog();

  @override
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    log = CrashlyticsAppLog(
      Logger(
        printer: PrettyPrinter(),
        output: MultiOutput([
          if (kDebugMode) ConsoleOutput(),
          CrashlyticsOutput(crashlytics),
        ]),
      ),
      crashlytics,
    );
  }
}
