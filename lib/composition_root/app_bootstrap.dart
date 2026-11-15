import 'package:memora/presentation/app/startup_background_tasks.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/offline_backup_providers.dart';
import 'package:memora/infrastructure/android_widget/android_widget_interactivity_callback.dart';

Future<void> initializeAppDisplay() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}

Future<void> launchApp(Widget app) async {
  final root = AppCompositionRoot.fromBuildConfiguration();
  await runZonedGuarded<Future<void>>(
    () async {
      await initializeAppDisplay();
      final container = root.createContainer();
      try {
        await root.initialize(availabilityContainer: container);
        FlutterError.onError = (details) {
          unawaited(
            root.services.log.recordError(details.exception, details.stack),
          );
        };
        registerAndroidWidgetInteractivityCallback();
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
        root.services.log.i(
          'MEMORA_APP_MODE=${root.requestedValue ?? root.mode.name}, AppMode=${root.mode.name}',
        );
        runApp(
          UncontrolledProviderScope(
            container: container,
            child: StartupBackgroundTasks(child: app),
          ),
        );
      } catch (_) {
        container.dispose();
        rethrow;
      }
    },
    (error, stack) {
      unawaited(root.services.log.recordError(error, stack, fatal: true));
    },
  );
}
