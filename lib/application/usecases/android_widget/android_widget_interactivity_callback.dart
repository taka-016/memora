import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:memora/application/usecases/android_widget/android_widget_action_handler.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/firebase_options.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_trip_entry_query_service.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';

@pragma('vm:entry-point')
FutureOr<void> androidWidgetInteractivityCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final storage = const HomeWidgetAndroidWidgetCacheStorage();
  final getCacheUsecase = GetAndroidWidgetItineraryCacheUsecase(
    tripEntryQueryService: FirestoreTripEntryQueryService(
      firestore: FirebaseFirestore.instance,
      clock: NtpSynchronizedAppClock(),
      rethrowOnError: true,
    ),
    itineraryItemQueryService: FirestoreItineraryItemQueryService(
      firestore: FirebaseFirestore.instance,
      rethrowOnError: true,
    ),
    clock: NtpSynchronizedAppClock(),
  );
  final refreshUsecase = RefreshAndroidWidgetItineraryCacheUsecase(
    cacheStorage: storage,
    getCacheUsecase: getCacheUsecase,
  );
  final moveUsecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
    cacheStorage: storage,
    tripEntryQueryService: FirestoreTripEntryQueryService(
      firestore: FirebaseFirestore.instance,
      clock: NtpSynchronizedAppClock(),
      rethrowOnError: true,
    ),
    itineraryItemQueryService: FirestoreItineraryItemQueryService(
      firestore: FirebaseFirestore.instance,
      rethrowOnError: true,
    ),
    refreshCacheUsecase: refreshUsecase,
  );
  const toastNotifier = MethodChannelAndroidWidgetToastNotifier();
  final actionHandler = AndroidWidgetActionHandler(
    cacheStorage: storage,
    refreshCache: refreshUsecase.execute,
    moveDate: moveUsecase.execute,
    showToast: toastNotifier.show,
  );

  await actionHandler.handle(uri);
}

void registerAndroidWidgetInteractivityCallback() {
  HomeWidget.registerInteractivityCallback(androidWidgetInteractivityCallback);
}
