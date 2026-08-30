import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/app_mode_resolver.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_background_update.dart';
import 'package:memora/application/usecases/android_widget/android_widget_interactivity_callback.dart';
import 'package:memora/infrastructure/config/app_mode_build_configuration.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  final appModeBuildConfiguration = AppModeBuildConfiguration.fromEnvironment();
  final appMode = const AppModeResolver().resolve(
    forcedMode: appModeBuildConfiguration.forcedMode,
  );

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      registerAndroidWidgetInteractivityCallback();
      await initializeAndroidWidgetBackgroundUpdate();
      final androidWidgetUpdateInterval =
          await const SharedPreferencesAndroidWidgetUpdateIntervalStorage()
              .load();
      await registerAndroidWidgetPeriodicUpdateTask(
        androidWidgetUpdateInterval.duration,
      );
      await initLogger();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i(
        'MEMORA_APP_MODE=${appModeBuildConfiguration.requestedValue}, '
        'AppMode=${appMode.name}',
      );

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );

      final appClock = NtpSynchronizedAppClock();
      try {
        await appClock.sync();
      } catch (e, stack) {
        logger.w('NTP時刻の同期に失敗しました', error: e, stackTrace: stack);
      }

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      runApp(
        ProviderScope(
          overrides: [
            appClockProvider.overrideWithValue(appClock),
            androidWidgetCacheStorageProvider.overrideWithValue(
              const HomeWidgetAndroidWidgetCacheStorage(),
            ),
            androidWidgetUpdateIntervalStorageProvider.overrideWithValue(
              const SharedPreferencesAndroidWidgetUpdateIntervalStorage(),
            ),
          ],
          child: const AppClockLifecycleSync(child: MyApp()),
        ),
      );
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class AppClockLifecycleSync extends ConsumerStatefulWidget {
  const AppClockLifecycleSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppClockLifecycleSync> createState() =>
      _AppClockLifecycleSyncState();
}

class _AppClockLifecycleSyncState extends ConsumerState<AppClockLifecycleSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncClock());
    }
  }

  Future<void> _syncClock() async {
    try {
      await ref.read(appClockProvider).sync();
    } catch (e, stack) {
      logger.w('NTP時刻の再同期に失敗しました', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(androidWidgetLaunchNotifierProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterConfigProvider),
      title: 'memora',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        buttonTheme: const ButtonThemeData(alignedDropdown: true),
      ),
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
