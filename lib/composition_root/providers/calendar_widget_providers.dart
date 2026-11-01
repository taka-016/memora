import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

final refreshCalendarWidgetProvider = Provider<Future<void> Function(String, DateTime?)>((ref) {
  final usecase = GetAndroidWidgetCalendarCacheUsecase(
    events: ref.watch(calendarEventQueryServiceProvider),
    labels: ref.watch(calendarLabelQueryServiceProvider),
    groups: ref.watch(groupQueryServiceProvider),
    expander: ref.watch(calendarRecurrenceExpanderProvider),
    mode: ref.watch(appModeProvider),
  );
  final clock = ref.watch(appClockProvider);
  return (groupId, date) async {
    if (!Platform.isAndroid) return;
    const storage = HomeWidgetCalendarCacheStorage();
    final month = date ?? await storage.loadMonth() ?? clock.now();
    final cache = await usecase.execute(groupId, month);
    const target = HomeWidgetAndroidWidgetCacheStorage();
    if (await target.getTargetGroupId() != groupId) return;
    if (cache == null) {
      await storage.clear();
    } else {
      await storage.save(cache);
      if (date != null) {
        await HomeWidget.saveWidgetData<String>(
          HomeWidgetCalendarCacheStorage.selectedDateKey,
          DateFormat('yyyy-MM-dd').format(date),
        );
      }
    }
    await storage.update();
  };
});
