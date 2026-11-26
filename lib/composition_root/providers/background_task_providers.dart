import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/composition_root/calendar_notification_background.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/startup_background_registration.dart';
import 'package:memora/composition_root/android_widget_background_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

final startupBackgroundRegistrationProvider =
    Provider<StartupBackgroundRegistration>((ref) {
      final intervalStorage = ref.watch(
        androidWidgetUpdateIntervalStorageProvider,
      );
      return StartupBackgroundRegistration(
        loadRegistered: (task) async {
          final preferences = await SharedPreferences.getInstance();
          return preferences.getBool('background_task_registered_$task') ??
              false;
        },
        markRegistered: (task) async {
          final preferences = await SharedPreferences.getInstance();
          if (!await preferences.setBool(
            'background_task_registered_$task',
            true,
          )) {
            throw StateError('定期タスクの登録状態を保存できませんでした');
          }
        },
        initialize: initializeAndroidWidgetBackgroundUpdate,
        registerNotifications: registerCalendarNotificationBackgroundUpdate,
        loadWidgetInterval: () async => (await intervalStorage.load()).duration,
        registerWidget: registerAndroidWidgetPeriodicUpdateTask,
      );
    });
