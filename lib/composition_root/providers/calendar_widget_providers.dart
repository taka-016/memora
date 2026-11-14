import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/android_widget/get_calendar_widget_selection_usecase.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

final getCalendarWidgetSelectionUsecaseProvider = Provider<GetCalendarWidgetSelectionUsecase>((ref) => GetCalendarWidgetSelectionUsecase(
  mode: ref.watch(appModeProvider), currentMember: ref.watch(getCurrentMemberUsecaseProvider),
  groups: ref.watch(getGroupsWithMembersUsecaseProvider), storage: ref.watch(calendarGroupSettingsStorageProvider),
));

final refreshCalendarWidgetProvider =
    Provider<Future<void> Function(String, DateTime?)>((ref) {
      var generation = 0;
      Future<void> pending = Future.value();
      return (_, date) async {
        if (!Platform.isAndroid) return;
        if (!(await ref.read(loadInstalledAndroidWidgetKindsProvider)()).contains(AndroidWidgetKind.calendar)) return;
        final request = ++generation;
        const storage = HomeWidgetCalendarCacheStorage();
        await storage.setScope(null);
        Future<void> refresh() async {
          if (!ref.mounted || request != generation) return;
          final selectionUsecase = ref.read(getCalendarWidgetSelectionUsecaseProvider);
          final selection = await selectionUsecase.execute();
          if (!ref.mounted || request != generation) return;
          if (selection == null) {
            await storage.clear();
            await storage.update();
            return;
          }
          await storage.setScope(selection.cacheScope);
          final usecase = GetAndroidWidgetCalendarCacheUsecase(
            events: ref.read(calendarEventQueryServiceProvider),
            labels: ref.read(calendarLabelQueryServiceProvider),
            groups: ref.read(groupQueryServiceProvider),
            expander: ref.read(calendarRecurrenceExpanderProvider),
            mode: ref.read(appModeProvider),
            currentUser: ref.read(appModeProvider) == AppMode.online ? ref.read(authServiceProvider) : null,
          );
          final clock = ref.read(appClockProvider);
          final month = date ?? await storage.loadSelectedDate() ?? await storage.loadMonth() ?? clock.now();
          await storage.refresh(selection.cacheScope, month, () async {
            final cache = await usecase.execute(selection.visibleGroupIds, month, ownerId: selection.ownerId);
            final latest = await selectionUsecase.execute();
            if (!ref.mounted || request != generation || latest?.cacheScope != selection.cacheScope) return;
            if (cache == null) return;
            await storage.save({...cache, 'lastUpdatedAt': clock.now().toIso8601String()}, merge: date != null);
          });
        }
        final result = pending.then((_) => refresh());
        pending = result.catchError((Object _) {});
        await result;
      };
    });
