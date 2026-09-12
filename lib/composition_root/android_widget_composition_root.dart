import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_mode_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_action_handler.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';

Future<void> withAndroidWidgetDependencies(
  Future<void> Function(
    RefreshAndroidWidgetItineraryCacheUsecase refresh,
    AndroidWidgetActionHandler handler,
  )
  action, {
  OfflineDatabase Function()? createOfflineDatabase,
  AndroidWidgetCacheStorage? cacheStorage,
}) async {
  final mode = await const SharedPreferencesAppModeStorage()
      .loadForCurrentBuild();
  if (mode == null) {
    throw StateError('ウィジェット更新用のモードが未保存、または現ビルドと一致しません');
  }
  final root = AppCompositionRoot(mode);
  await root.initialize();
  final database = mode == AppMode.offline
      ? (createOfflineDatabase ?? OfflineDatabase.device)()
      : null;
  final container = ProviderContainer(
    overrides: [
      ...root.overrides,
      if (database != null) offlineDatabaseProvider.overrideWithValue(database),
    ],
  );
  try {
    await database?.initialize();
    final AndroidWidgetCacheStorage storage =
        cacheStorage ?? container.read(androidWidgetCacheStorageProvider);
    final trips = container.read(mapTripEntryQueryServiceProvider);
    final items = container.read(
      androidWidgetItineraryItemQueryServiceProvider,
    );
    final refresh = RefreshAndroidWidgetItineraryCacheUsecase(
      cacheStorage: storage,
      getCacheUsecase: container.read(
        getAndroidWidgetItineraryCacheUsecaseProvider,
      ),
    );
    final move = MoveAndroidWidgetSelectedItineraryDateUsecase(
      cacheStorage: storage,
      tripEntryQueryService: trips,
      itineraryItemQueryService: items,
      refreshCacheUsecase: refresh,
    );
    final handler = AndroidWidgetActionHandler(
      cacheStorage: storage,
      refreshCache: refresh.execute,
      moveDate: move.execute,
      showToast: const MethodChannelAndroidWidgetToastNotifier().show,
    );
    await action(refresh, handler);
  } finally {
    container.dispose();
    await database?.close();
  }
}
