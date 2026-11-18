import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/infrastructure/config/firestore_emulator_configuration.dart';
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
  OnlineAppServices()
    : _emulator = FirestoreEmulatorConfiguration.fromEnvironment();

  final FirestoreEmulatorConfiguration? _emulator;
  static Future<void>? _emulatorInitialization;

  Future<void> _initializeEmulator(
    FirestoreEmulatorConfiguration config,
  ) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: 'read-regression-test-key',
          appId: '1:1:android:1',
          messagingSenderId: '1',
          projectId: config.projectId,
        ),
      );
    }
    if (Firebase.app().options.projectId != config.projectId) {
      throw StateError('テスト専用以外のFirebaseプロジェクトが初期化されています');
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      config.host,
      config.firestorePort,
      automaticHostMapping: false,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      config.host,
      config.authPort,
      automaticHostMapping: false,
    );
  }

  @override
  late final AppClock clock = _emulator?.clock ?? NtpSynchronizedAppClock();

  @override
  AppLog log = kDebugMode
      ? DeviceAppLog(Logger(printer: PrettyPrinter(), output: ConsoleOutput()))
      : const SilentAppLog();

  @override
  Future<void> initialize() async {
    final emulator = _emulator;
    if (emulator != null) {
      await (_emulatorInitialization ??= _initializeEmulator(emulator));
      return;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
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
