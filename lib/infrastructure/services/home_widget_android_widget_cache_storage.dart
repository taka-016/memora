import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  const HomeWidgetAndroidWidgetCacheStorage();

  static const targetGroupIdKey = 'memora_widget_target_group_id';
  static const selectedItineraryDateIdKey =
      'memora_widget_selected_itinerary_date_id';
  static const lastUpdatedAtKey = 'memora_widget_last_updated_at';
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
    return (await loadItineraryCache())?.selectedItineraryDateId;
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
    await _saveCacheFile(Uint8List.fromList(utf8.encode(json)));
    await HomeWidget.saveWidgetData<String>(
      lastUpdatedAtKey,
      cache.lastUpdatedAt.toIso8601String(),
    );
  }

  Future<void> _saveCacheFile(Uint8List bytes) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final widgetDirectory = Directory('${supportDirectory.path}/home_widget');
    await widgetDirectory.create(recursive: true);
    final suffix =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${Random.secure().nextInt(1 << 32)}';
    final temporaryFile = File(
      '${widgetDirectory.path}/$cacheFileKey.$suffix.tmp',
    );
    await temporaryFile.create(exclusive: true);
    try {
      await temporaryFile.writeAsBytes(bytes, flush: true);
      final publishedFile = await temporaryFile.rename(
        '${widgetDirectory.path}/$cacheFileKey.json',
      );
      await HomeWidget.saveWidgetData<String>(
        cacheFileKey,
        publishedFile.path,
        deleteFile: false,
      );
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      clearTargetGroupId(),
      HomeWidget.saveWidgetData<String>(selectedItineraryDateIdKey, ''),
      HomeWidget.saveWidgetData<String>(lastUpdatedAtKey, ''),
      HomeWidget.saveWidgetData<String>(cacheFileKey, null),
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
