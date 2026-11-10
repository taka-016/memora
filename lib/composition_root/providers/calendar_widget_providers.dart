import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

final refreshCalendarWidgetProvider =
    Provider<Future<void> Function(String, DateTime?)>((ref) {
      return (groupId, date) async {
        if (!Platform.isAndroid) return;
        if (!(await ref.read(
          loadInstalledAndroidWidgetKindsProvider,
        )()).contains(AndroidWidgetKind.calendar)) {
          return;
        }
        final target = ref.read(androidWidgetCacheStorageProvider);
        if (await target.getTargetGroupId() != groupId) return;
        final usecase = GetAndroidWidgetCalendarCacheUsecase(
          events: ref.read(calendarEventQueryServiceProvider),
          labels: ref.read(calendarLabelQueryServiceProvider),
          groups: ref.read(groupQueryServiceProvider),
          expander: ref.read(calendarRecurrenceExpanderProvider),
          mode: ref.read(appModeProvider),
          currentUser: ref.read(appModeProvider) == AppMode.online
              ? ref.read(authServiceProvider)
              : null,
        );
        final clock = ref.read(appClockProvider);
        const storage = HomeWidgetCalendarCacheStorage();
        final month =
            date ??
            await storage.loadSelectedDate() ??
            await storage.loadMonth() ??
            clock.now();
        await storage.refresh(groupId, month, () async {
          final cache = await usecase.execute(groupId, month);
          if (await target.getTargetGroupId() != groupId) return;
          if (cache == null) {
            await target.clear();
          } else {
            await storage.save({
              ...cache,
              'lastUpdatedAt': clock.now().toIso8601String(),
            }, merge: date != null);
          }
        });
      };
    });
