import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';

class HomeWidgetAndroidWidgetCacheStorage
    implements AndroidWidgetCacheStorage, AndroidWidgetCacheGenerationStorage {
  const HomeWidgetAndroidWidgetCacheStorage();

  static const targetGroupIdKey = 'memora_widget_target_group_id';
  static const selectedItineraryDateIdKey =
      'memora_widget_selected_itinerary_date_id';
  static const lastUpdatedAtKey = 'memora_widget_last_updated_at';
  static const cacheFileKey = 'memora_widget_itinerary_cache';
  static const cacheGenerationKey = 'memora_widget_cache_generation';
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
    final generation = await getCacheGeneration();
    final value =
        await HomeWidget.getWidgetData<String>(
          _generationKey(selectedItineraryDateIdKey, generation),
        ) ??
        (generation == 0
            ? await HomeWidget.getWidgetData<String>(selectedItineraryDateIdKey)
            : null);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    final generation = await getCacheGeneration();
    await HomeWidget.saveWidgetData<String>(
      _generationKey(selectedItineraryDateIdKey, generation),
      itineraryDateId ?? '',
    );
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    final generation = await getCacheGeneration();
    final path =
        await HomeWidget.getWidgetData<String>(
          _generationKey(cacheFileKey, generation),
        ) ??
        (generation == 0
            ? await HomeWidget.getWidgetData<String>(cacheFileKey)
            : null);
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
    final cache = AndroidWidgetItineraryCacheDto.fromJson(decoded);
    return cache.generation == generation ? cache : null;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    final generation = await getCacheGeneration();
    await saveItineraryCacheForGeneration(
      AndroidWidgetItineraryCacheDto(
        version: cache.version,
        sourceMode: cache.sourceMode,
        generation: generation,
        groupId: cache.groupId,
        selectedItineraryDateId: cache.selectedItineraryDateId,
        lastUpdatedAt: cache.lastUpdatedAt,
        itineraryDates: cache.itineraryDates,
      ),
    );
  }

  @override
  Future<void> saveItineraryCacheForGeneration(
    AndroidWidgetItineraryCacheDto cache,
  ) async {
    final json = jsonEncode(cache.toJson());
    final generation = cache.generation;
    await HomeWidget.saveFile(
      _generationKey(cacheFileKey, generation),
      Uint8List.fromList(utf8.encode(json)),
      extension: 'json',
    );
    await Future.wait([
      HomeWidget.saveWidgetData<String>(
        _generationKey(selectedItineraryDateIdKey, generation),
        cache.selectedItineraryDateId ?? '',
      ),
      HomeWidget.saveWidgetData<String>(
        _generationKey(lastUpdatedAtKey, generation),
        cache.lastUpdatedAt.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<int> getCacheGeneration() async {
    return await HomeWidget.getWidgetData<int>(
          cacheGenerationKey,
          defaultValue: 0,
        ) ??
        0;
  }

  @override
  Future<int> advanceCacheGeneration({
    AndroidWidgetItineraryCacheDto? cache,
  }) async {
    final generation = await getCacheGeneration() + 1;
    if (cache != null) {
      await saveItineraryCacheForGeneration(
        AndroidWidgetItineraryCacheDto(
          version: cache.version,
          sourceMode: cache.sourceMode,
          generation: generation,
          groupId: cache.groupId,
          selectedItineraryDateId: cache.selectedItineraryDateId,
          lastUpdatedAt: cache.lastUpdatedAt,
          itineraryDates: cache.itineraryDates,
        ),
      );
    }
    await HomeWidget.saveWidgetData<int>(cacheGenerationKey, generation);
    return generation;
  }

  @override
  Future<void> clear() async {
    final previousGeneration = await getCacheGeneration();
    final generation = await advanceCacheGeneration();
    await Future.wait([
      clearTargetGroupId(),
      HomeWidget.saveWidgetData<String>(
        _generationKey(selectedItineraryDateIdKey, generation),
        '',
      ),
      HomeWidget.saveWidgetData<String>(lastUpdatedAtKey, ''),
      HomeWidget.saveWidgetData<String>(cacheFileKey, ''),
      HomeWidget.saveWidgetData<String>(
        _generationKey(cacheFileKey, previousGeneration),
        null,
      ),
    ]);
  }

  @override
  Future<void> updateWidget() async {
    if (!Platform.isAndroid) {
      return;
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
  }

  static String _generationKey(String key, int generation) {
    return '${key}_$generation';
  }
}
