import 'package:memora/application/dtos/android_widget/android_widget_action_result_dto.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';

abstract interface class AndroidWidgetCacheStorage {
  Future<String?> getTargetGroupId();

  Future<void> saveTargetGroupId(String groupId);

  Future<void> clearTargetGroupId();

  Future<String?> getSelectedItineraryDateId();

  Future<void> saveSelectedItineraryDateId(String? itineraryDateId);

  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache();

  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache);

  Future<void> saveActionResult(
    String actionId,
    AndroidWidgetActionResultDto result,
  );

  Future<void> clear();

  Future<void> updateWidget();
}
