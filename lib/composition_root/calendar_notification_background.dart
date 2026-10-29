import 'dart:io';

import 'package:workmanager/workmanager.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/composition_root/providers/offline_backup_operation_lock_provider.dart';
import 'package:memora/infrastructure/backup/offline_backup_restore_recovery.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_mode_storage.dart';

const calendarNotificationPeriodicTaskName =
    'memora_calendar_notification_refresh';

Future<void> registerCalendarNotificationBackgroundUpdate() async {
  if (!Platform.isAndroid) return;
  final mode = await const SharedPreferencesAppModeStorage()
      .loadForCurrentBuild();
  if (mode == null) return;
  await Workmanager().registerPeriodicTask(
    calendarNotificationPeriodicTaskName,
    calendarNotificationPeriodicTaskName,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: mode == AppMode.online
          ? NetworkType.connected
          : NetworkType.notRequired,
    ),
  );
}

Future<bool> refreshCalendarNotificationsInBackground() async {
  final mode = await const SharedPreferencesAppModeStorage()
      .loadForCurrentBuild();
  if (mode == null) return true;
  final root = AppCompositionRoot(mode);
  await root.initialize();
  final container = root.createContainer();
  try {
    Future<bool> synchronize() async =>
        await container
            .read(synchronizeCalendarNotificationsUsecaseProvider)
            .execute() !=
        CalendarNotificationStatus.failed;
    if (mode == AppMode.online) return await synchronize();
    final database = container.read(offlineDatabaseProvider);
    await database.initialize();
    await recoverPendingOfflineBackupRestore(database: database);
    return await container
        .read(offlineBackupRestoreOperationLockProvider)
        .run(synchronize);
  } finally {
    container.dispose();
  }
}
