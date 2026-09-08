import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/services/android_widget_update_interval_storage.dart';
import 'package:memora/infrastructure/android_widget/android_widget_background_update.dart';
import 'package:memora/infrastructure/android_widget/android_widget_interactivity_callback.dart';

Future<void> launchApp(Widget app) async {
  final root = AppCompositionRoot.fromBuildConfiguration();
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
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
