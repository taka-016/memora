import 'package:memora/application/usecases/android_widget/android_widget_action_handler.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/services/android_widget_cache_storage.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';

Future<void> withAndroidWidgetDependencies(
  Future<void> Function(
    RefreshAndroidWidgetItineraryCacheUsecase refresh,
    AndroidWidgetActionHandler handler,
  )
  action,
) async {
  final root = AppCompositionRoot.fromBuildConfiguration();
  await root.initialize();
  final container = root.createContainer();
  try {
    final storage = container.read(androidWidgetCacheStorageProvider);
    final trips = container.read(mapTripEntryQueryServiceProvider);
    final items = container.read(
      androidWidgetItineraryItemQueryServiceProvider,
    );
    final refresh = RefreshAndroidWidgetItineraryCacheUsecase(
      cacheStorage: storage,
      getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
        tripEntryQueryService: trips,
        itineraryItemQueryService: items,
        clock: root.services.clock,
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
  }
}
