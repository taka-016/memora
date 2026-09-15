import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';

typedef AndroidWidgetCacheGenerationUpdate =
    AndroidWidgetItineraryCacheDto? Function(
      AndroidWidgetItineraryCacheDto? currentCache,
    );

abstract interface class AndroidWidgetCacheStorage {
  Future<String?> getTargetGroupId();

  Future<void> saveTargetGroupId(String groupId);

  Future<void> clearTargetGroupId();

  Future<String?> getSelectedItineraryDateId();

  Future<void> saveSelectedItineraryDateId(String? itineraryDateId);

  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache();

  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache);

  Future<void> clear();

  Future<void> updateWidget();
}

abstract interface class AndroidWidgetCacheGenerationStorage {
  Future<int> getCacheGeneration();

  Future<int> advanceCacheGeneration({
    AndroidWidgetCacheGenerationUpdate? updateCache,
  });

  Future<void> saveItineraryCacheForGeneration(
    AndroidWidgetItineraryCacheDto cache,
  );
}
