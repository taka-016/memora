import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';

abstract interface class AndroidWidgetCacheStorage {
  Future<String?> getTargetGroupId();

  Future<void> saveTargetGroupId(String groupId);

  Future<void> clearTargetGroupId();

  Future<String?> getSelectedTripId();

  Future<void> saveSelectedTripId(String? tripId);

  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache();

  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache);

  Future<void> saveErrorMessage(String? message);

  Future<void> clear();

  Future<void> updateWidget();
}
