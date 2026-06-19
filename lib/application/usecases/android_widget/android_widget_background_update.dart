import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/firebase_options.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_trip_entry_query_service.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';
import 'package:workmanager/workmanager.dart';

const androidWidgetPeriodicUpdateUniqueName =
    'memora_android_widget_periodic_update';
const androidWidgetPeriodicUpdateTaskName =
    'memora_android_widget_periodic_update_task';
const androidWidgetShortUpdateTaskName =
    'memora_android_widget_short_update_task';
const _androidWidgetShortUpdateFirstUniqueName =
    'memora_android_widget_short_update_first';
const _androidWidgetShortUpdateSecondUniqueName =
    'memora_android_widget_short_update_second';
const _shortUpdateNextUniqueNameKey = 'nextUniqueName';
const _minimumPeriodicUpdateInterval = Duration(minutes: 15);
final _connectedNetworkConstraints = Constraints(
  networkType: NetworkType.connected,
);

Future<void> initializeAndroidWidgetBackgroundUpdate() async {
  if (!Platform.isAndroid) {
    return;
  }
  await Workmanager().initialize(androidWidgetBackgroundUpdateDispatcher);
}

Future<void> registerAndroidWidgetPeriodicUpdateTask(Duration frequency) async {
  if (!Platform.isAndroid) {
    return;
  }
  final workmanager = Workmanager();
  if (frequency < _minimumPeriodicUpdateInterval) {
    await Future.wait([
      workmanager.cancelByUniqueName(androidWidgetPeriodicUpdateUniqueName),
      workmanager.cancelByUniqueName(_androidWidgetShortUpdateFirstUniqueName),
      workmanager.cancelByUniqueName(_androidWidgetShortUpdateSecondUniqueName),
    ]);
    await _registerAndroidWidgetShortUpdateTask(
      uniqueName: _androidWidgetShortUpdateFirstUniqueName,
      nextUniqueName: _androidWidgetShortUpdateSecondUniqueName,
      frequency: frequency,
    );
    return;
  }
  await Future.wait([
    workmanager.cancelByUniqueName(_androidWidgetShortUpdateFirstUniqueName),
    workmanager.cancelByUniqueName(_androidWidgetShortUpdateSecondUniqueName),
  ]);
  await workmanager.registerPeriodicTask(
    androidWidgetPeriodicUpdateUniqueName,
    androidWidgetPeriodicUpdateTaskName,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    frequency: frequency,
    constraints: _connectedNetworkConstraints,
  );
}

Future<void> _registerAndroidWidgetShortUpdateTask({
  required String uniqueName,
  required String nextUniqueName,
  required Duration frequency,
}) async {
  await Workmanager().registerOneOffTask(
    uniqueName,
    androidWidgetShortUpdateTaskName,
    inputData: {_shortUpdateNextUniqueNameKey: nextUniqueName},
    initialDelay: frequency,
    constraints: _connectedNetworkConstraints,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

@pragma('vm:entry-point')
void androidWidgetBackgroundUpdateDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != androidWidgetPeriodicUpdateTaskName &&
        task != androidWidgetShortUpdateTaskName) {
      return true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    if (task == androidWidgetPeriodicUpdateTaskName) {
      return await _refreshAndroidWidgetFromBackground();
    }
    final succeeded = await _refreshAndroidWidgetFromBackground();
    if (succeeded) {
      await _registerNextAndroidWidgetShortUpdateTask(inputData);
    }
    return succeeded;
  });
}

Future<void> _registerNextAndroidWidgetShortUpdateTask(
  Map<String, dynamic>? inputData,
) async {
  final nextUniqueName = inputData?[_shortUpdateNextUniqueNameKey];
  if (nextUniqueName is! String) {
    return;
  }
  final interval =
      await const SharedPreferencesAndroidWidgetUpdateIntervalStorage().load();
  final frequency = interval.duration;
  if (frequency >= _minimumPeriodicUpdateInterval) {
    return;
  }
  final followingUniqueName =
      nextUniqueName == _androidWidgetShortUpdateFirstUniqueName
      ? _androidWidgetShortUpdateSecondUniqueName
      : _androidWidgetShortUpdateFirstUniqueName;
  await _registerAndroidWidgetShortUpdateTask(
    uniqueName: nextUniqueName,
    nextUniqueName: followingUniqueName,
    frequency: frequency,
  );
}

Future<bool> _refreshAndroidWidgetFromBackground() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  const storage = HomeWidgetAndroidWidgetCacheStorage();
  final groupId = await storage.getTargetGroupId();
  if (groupId == null) {
    await storage.updateWidget();
    return true;
  }

  final clock = NtpSynchronizedAppClock();
  final refreshUsecase = RefreshAndroidWidgetItineraryCacheUsecase(
    cacheStorage: storage,
    getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
      tripEntryQueryService: FirestoreTripEntryQueryService(
        firestore: FirebaseFirestore.instance,
        clock: clock,
        rethrowOnError: true,
      ),
      itineraryItemQueryService: FirestoreItineraryItemQueryService(
        firestore: FirebaseFirestore.instance,
        rethrowOnError: true,
      ),
      clock: clock,
    ),
  );

  try {
    await refreshUsecase.execute(
      groupId: groupId,
      selectedItineraryDateId: await storage.getSelectedItineraryDateId(),
    );
  } catch (_) {
    await storage.updateWidget();
    await _showUpdateFailedToast();
    return false;
  }
  return true;
}

Future<void> _showUpdateFailedToast() async {
  try {
    await const MethodChannelAndroidWidgetToastNotifier().show(
      const AndroidWidgetToastNotification.error('更新に失敗しました'),
    );
  } catch (_) {}
}
