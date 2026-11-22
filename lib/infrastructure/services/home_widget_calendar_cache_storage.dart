import 'package:memora/infrastructure/services/local_calendar_widget_lock.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';

import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:memora/infrastructure/services/home_widget_load_state_storage.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetCalendarCacheStorage {
  const HomeWidgetCalendarCacheStorage();

  Future<void> synchronize(Future<void> Function() action) =>
      LocalCalendarWidgetLock().run('refresh', action);

  Future<String?> loadScope() => HomeWidget.getWidgetData<String>(scopeKey);

  static const cacheKey = 'memora_widget_calendar_cache';
  static const scopeKey = 'memora_widget_calendar_scope';

  Future<T> _synchronizeScope<T>(Future<T> Function() action) =>
      LocalCalendarWidgetLock().run('scope', action);

  /// 表示対象を保存し、公開済みキャッシュの更新が必要かを返す。
  Future<bool> setScope(String? scope) async {
    final changed = await _synchronizeScope(() async {
      if (await loadScope() == scope) return false;
      await HomeWidget.saveWidgetData<String>(scopeKey, scope);
      return true;
    });
    if (changed) {
      await update();
      return true;
    }
    if (scope == null || await _hasPublishedScope(scope)) return false;
    // 先に始まったウィジェット更新が公開するまで待ち、再取得の要否を確認する。
    return LocalCalendarWidgetLock().run(
      'refresh',
      () async =>
          await loadScope() == scope && !await _hasPublishedScope(scope),
    );
  }

  Future<bool> _hasPublishedScope(String scope) async =>
      (await _load())?['cacheScope'] == scope;

  Future<bool> setScopeIfCurrent(String? expected, String? scope) async {
    final changed = await _synchronizeScope(() async {
      if (await loadScope() != expected) return false;
      await HomeWidget.saveWidgetData<String>(scopeKey, scope);
      return true;
    });
    if (changed) await update();
    return changed;
  }

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
    if (path == null) return null;
    try {
      final data = jsonDecode(await File(path).readAsString());
      return data is Map<String, dynamic> ? data : null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<DateTime?> loadMonth() async {
    final data = await _load();
    final month = data?['month'];
    return month is String ? DateTime.tryParse(month) : null;
  }

  Future<DateTime?> loadSelectedDate() async {
    final value = await HomeWidget.getWidgetData<String>(selectedDateKey);
    return DateTime.tryParse(value ?? '');
  }

  Future<void> save(
    Map<String, Object?> cache, {
    int? retainMonthsWithin,
  }) async {
    final previous = retainMonthsWithin == 0 ? null : await _load();
    final previousMonths = previous?['months'];
    final incomingMonths = cache['months'] as Map<String, Object?>?;
    final refreshedMonth = DateTime.parse(cache['month'] as String);
    int distance(DateTime date, DateTime month) {
      return ((date.year - month.year) * 12 + date.month - month.month).abs();
    }

    final months = <String, Object?>{
      if (previousMonths is Map<String, dynamic> &&
          previous?['cacheScope'] == cache['cacheScope'] &&
          previous?['groupId'] == cache['groupId'] &&
          previous?['sourceMode'] == cache['sourceMode'])
        for (final entry in previousMonths.entries)
          if (DateTime.tryParse(entry.key) case final date?)
            if (retainMonthsWithin == null ||
                distance(date, refreshedMonth) <= retainMonthsWithin)
              entry.key: entry.value,
      ...?incomingMonths,
    };
    final selected = await loadSelectedDate() ?? refreshedMonth;
    final keys = months.keys.toList()
      ..sort((a, b) {
        final result = distance(
          DateTime.parse(a),
          selected,
        ).compareTo(distance(DateTime.parse(b), selected));
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
      final lastUpdatedAt = cache['lastUpdatedAt'] as String?;
      if (lastUpdatedAt != null) {
        await HomeWidget.saveWidgetData<String>(
          HomeWidgetAndroidWidgetCacheStorage.lastUpdatedAtKey,
          lastUpdatedAt,
        );
      }
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  Future<void> clear() async {
    await _synchronizeScope(
      () => HomeWidget.saveWidgetData<String>(scopeKey, null),
    );
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
