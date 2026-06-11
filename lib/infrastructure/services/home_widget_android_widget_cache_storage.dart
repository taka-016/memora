import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';
import 'package:memora/application/dtos/android_widget/android_widget_action_result_dto.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';

class HomeWidgetAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  const HomeWidgetAndroidWidgetCacheStorage();

  static const targetGroupIdKey = 'memora_widget_target_group_id';
  static const selectedItineraryDateIdKey =
      'memora_widget_selected_itinerary_date_id';
  static const lastUpdatedAtKey = 'memora_widget_last_updated_at';
  static const actionResultKeyPrefix = 'memora_widget_action_result_';
  static const cacheFileKey = 'memora_widget_itinerary_cache';
  static const qualifiedAndroidName =
      'com.example.memora.ItineraryWidgetReceiver';

  @override
  Future<String?> getTargetGroupId() async {
    final value = await HomeWidget.getWidgetData<String>(targetGroupIdKey);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    await HomeWidget.saveWidgetData<String>(targetGroupIdKey, groupId);
  }

  @override
  Future<void> clearTargetGroupId() async {
    await HomeWidget.saveWidgetData<String>(targetGroupIdKey, '');
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    final value = await HomeWidget.getWidgetData<String>(
      selectedItineraryDateIdKey,
    );
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    await HomeWidget.saveWidgetData<String>(
      selectedItineraryDateIdKey,
      itineraryDateId ?? '',
    );
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    final path = await HomeWidget.getWidgetData<String>(cacheFileKey);
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return AndroidWidgetItineraryCacheDto.fromJson(decoded);
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    final json = jsonEncode(cache.toJson());
    await HomeWidget.saveFile(
      cacheFileKey,
      Uint8List.fromList(utf8.encode(json)),
      extension: 'json',
    );
    await Future.wait([
      saveSelectedItineraryDateId(cache.selectedItineraryDateId),
      HomeWidget.saveWidgetData<String>(
        lastUpdatedAtKey,
        cache.lastUpdatedAt.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<void> saveActionResult(
    String actionId,
    AndroidWidgetActionResultDto result,
  ) async {
    await HomeWidget.saveWidgetData<String>(
      '$actionResultKeyPrefix$actionId',
      jsonEncode(result.toJson()),
    );
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      clearTargetGroupId(),
      saveSelectedItineraryDateId(null),
      HomeWidget.saveWidgetData<String>(lastUpdatedAtKey, ''),
      HomeWidget.saveWidgetData<String>(cacheFileKey, ''),
    ]);
  }

  @override
  Future<void> updateWidget() async {
    if (!Platform.isAndroid) {
      return;
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
  }
}
