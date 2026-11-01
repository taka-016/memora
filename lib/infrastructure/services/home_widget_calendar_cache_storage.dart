import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetCalendarCacheStorage {
  const HomeWidgetCalendarCacheStorage();

  static const cacheKey = 'memora_widget_calendar_cache';
  static const selectedDateKey = 'memora_widget_calendar_selected_date';
  static const qualifiedAndroidName = 'com.example.memora.CalendarWidgetReceiver';

  Future<DateTime?> loadMonth() async {
    final path = await HomeWidget.getWidgetData<String>(cacheKey);
    if (path == null || !await File(path).exists()) return null;
    final data = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    return DateTime.tryParse(data['month'] as String? ?? '');
  }

  Future<void> save(Map<String, Object?> cache) async {
    final directory = await getApplicationSupportDirectory();
    final folder = Directory('${directory.path}/home_widget');
    await folder.create(recursive: true);
    final temporary = await File('${folder.path}/$cacheKey.json').parent.createTemp('calendar-');
    try {
      final file = File('${temporary.path}/cache.json');
      await file.writeAsString(jsonEncode(cache), flush: true);
      final published = await file.rename('${folder.path}/$cacheKey.json');
      await HomeWidget.saveWidgetData<String>(cacheKey, published.path, deleteFile: false);
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
  }
}
