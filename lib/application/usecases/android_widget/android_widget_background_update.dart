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
import 'package:workmanager/workmanager.dart';

const androidWidgetPeriodicUpdateUniqueName =
    'memora_android_widget_periodic_update';
const androidWidgetPeriodicUpdateTaskName =
    'memora_android_widget_periodic_update_task';

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
  await Workmanager().registerPeriodicTask(
    androidWidgetPeriodicUpdateUniqueName,
    androidWidgetPeriodicUpdateTaskName,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    frequency: frequency,
  );
}

@pragma('vm:entry-point')
void androidWidgetBackgroundUpdateDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != androidWidgetPeriodicUpdateTaskName) {
      return true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    return await _refreshAndroidWidgetFromBackground();
  });
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
      ),
      itineraryItemQueryService: FirestoreItineraryItemQueryService(
        firestore: FirebaseFirestore.instance,
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
