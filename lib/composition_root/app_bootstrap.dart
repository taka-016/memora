import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/offline_backup_providers.dart';
import 'package:memora/infrastructure/android_widget/android_widget_background_update.dart';
import 'package:memora/infrastructure/android_widget/android_widget_interactivity_callback.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_mode_storage.dart';

Future<void> synchronizeAppModeAndAndroidWidgetCache(
  AppMode mode, {
  SharedPreferencesAppModeStorage modeStorage =
      const SharedPreferencesAppModeStorage(),
  AndroidWidgetCacheStorage cacheStorage =
      const HomeWidgetAndroidWidgetCacheStorage(),
}) async {
  final storedMode = await modeStorage.loadState();
  final previousMode = storedMode.mode;
  final shouldClearCache = previousMode == null
      ? storedMode.hasValue || mode == AppMode.offline
      : previousMode != mode;
  if (shouldClearCache) {
    await cacheStorage.clear();
    await cacheStorage.updateWidget();
  }
  await modeStorage.save(mode);
}

Future<void> launchApp(Widget app) async {
  final root = AppCompositionRoot.fromBuildConfiguration();
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await synchronizeAppModeAndAndroidWidgetCache(root.mode);
      await root.initialize();
      FlutterError.onError = (details) {
        unawaited(
          root.services.log.recordError(details.exception, details.stack),
        );
      };
      registerAndroidWidgetInteractivityCallback();
      await initializeAndroidWidgetBackgroundUpdate();
      final container = root.createContainer();
      try {
        if (root.mode == AppMode.offline) {
          try {
            await container
                .read(retryPendingOfflineBackupRestoreUsecaseProvider)
                .execute();
          } catch (error, stackTrace) {
            root.services.log.w(
              '復元後の派生データ同期を次回起動時に再試行します',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        final interval = await container
            .read(androidWidgetUpdateIntervalStorageProvider)
            .load();
        await registerAndroidWidgetPeriodicUpdateTask(interval.duration);
      } finally {
        container.dispose();
      }
      root.services.log.i(
        'MEMORA_APP_MODE=${root.requestedValue ?? root.mode.name}, AppMode=${root.mode.name}',
      );
      runApp(ProviderScope(overrides: root.overrides, child: app));
    },
    (error, stack) {
      unawaited(root.services.log.recordError(error, stack, fatal: true));
    },
  );
}
