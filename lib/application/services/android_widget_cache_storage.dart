import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';

enum AndroidWidgetNotificationType {
  toast('toast');

  const AndroidWidgetNotificationType(this.value);

  final String value;
}

class AndroidWidgetActionResult {
  const AndroidWidgetActionResult({
    required this.notificationType,
    required this.message,
    required this.isSuccess,
  });

  final AndroidWidgetNotificationType notificationType;
  final String? message;
  final bool isSuccess;

  Map<String, dynamic> toJson() {
    return {
      'notificationType': notificationType.value,
      'message': message,
      'isSuccess': isSuccess,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidWidgetActionResult &&
            other.notificationType == notificationType &&
            other.message == message &&
            other.isSuccess == isSuccess;
  }

  @override
  int get hashCode => Object.hash(notificationType, message, isSuccess);
}

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
    AndroidWidgetActionResult result,
  );

  Future<void> clear();

  Future<void> updateWidget();
}
