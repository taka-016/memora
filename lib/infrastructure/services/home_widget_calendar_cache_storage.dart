import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:memora/infrastructure/services/home_widget_load_state_storage.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetCalendarCacheStorage {
  const HomeWidgetCalendarCacheStorage();

  static const cacheKey = 'memora_widget_calendar_cache';
  static const selectedDateKey = 'memora_widget_calendar_selected_date';
  static const qualifiedAndroidName =
      'com.example.memora.CalendarWidgetReceiver';

  static String loadStateKey(String groupId, DateTime date) {
    final month = DateTime(
      date.year,
      date.month,
    ).toIso8601String().substring(0, 10);
    return 'memora_widget_calendar_load_${groupId}_$month';
  }

  Future<void> refresh(
    String groupId,
    DateTime month,
    Future<void> Function() action,
  ) async {
    await const HomeWidgetLoadStateStorage().track(
      loadStateKey(groupId, month),
      action,
      update: update,
    );
  }

  Future<Map<String, dynamic>?> _load() async {
    final path = await HomeWidget.getWidgetData<String>(cacheKey);
    if (path == null || !await File(path).exists()) return null;
    return jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
  }

  Future<DateTime?> loadMonth() async {
    final data = await _load();
    return DateTime.tryParse(data?['month'] as String? ?? '');
  }

  Future<DateTime?> loadSelectedDate() async {
    final value = await HomeWidget.getWidgetData<String>(selectedDateKey);
    return DateTime.tryParse(value ?? '');
  }

  Future<void> save(Map<String, Object?> cache, {bool merge = true}) async {
    final previous = merge ? await _load() : null;
    final previousMonths = previous?['months'] as Map<String, dynamic>?;
    final incomingMonths = cache['months'] as Map<String, Object?>?;
    final months = <String, Object?>{
      if (previous?['groupId'] == cache['groupId'] &&
          previous?['sourceMode'] == cache['sourceMode'])
        ...?previousMonths,
      ...?incomingMonths,
    };
    final selected =
        await loadSelectedDate() ?? DateTime.parse(cache['month'] as String);
    int distance(String key) {
      final month = DateTime.parse(key);
      return ((month.year - selected.year) * 12 + month.month - selected.month)
          .abs();
    }

    final keys = months.keys.toList()
      ..sort((a, b) {
        final result = distance(a).compareTo(distance(b));
        return result != 0 ? result : a.compareTo(b);
      });
    final publishedCache = {
      ...cache,
      'months': {for (final key in keys.take(7)) key: months[key]},
    };
    final directory = await getApplicationSupportDirectory();
    final folder = Directory('${directory.path}/home_widget');
    await folder.create(recursive: true);
    final temporary = await File('${folder.path}/$cacheKey.json').parent
        .createTemp('calendar-');
    try {
      final file = File('${temporary.path}/cache.json');
      await file.writeAsString(jsonEncode(publishedCache), flush: true);
      final published = await file.rename('${folder.path}/$cacheKey.json');
      await HomeWidget.saveWidgetData<String>(
        cacheKey,
        published.path,
        deleteFile: false,
      );
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  Future<void> clear() async {
    await HomeWidget.saveWidgetData<String>(cacheKey, null);
    await HomeWidget.saveWidgetData<String>(selectedDateKey, null);
  }

  Future<void> update() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.memora.CalendarDarkWidgetReceiver',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.memora.DailyCalendarWidgetReceiver',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'com.example.memora.DailyCalendarDarkWidgetReceiver',
    );
  }
}
