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

final getCalendarWidgetSelectionUsecaseProvider =
    Provider<GetCalendarWidgetSelectionUsecase>(
      (ref) => GetCalendarWidgetSelectionUsecase(
        mode: ref.watch(appModeProvider),
        currentMember: ref.watch(getCurrentMemberUsecaseProvider),
        groups: ref.watch(getGroupsWithMembersUsecaseProvider),
        storage: ref.watch(calendarGroupSettingsStorageProvider),
      ),
    );

final calendarWidgetSupportedProvider = Provider<bool>(
  (ref) => Platform.isAndroid,
);
final calendarWidgetCacheStorageProvider =
    Provider<HomeWidgetCalendarCacheStorage>(
      (ref) => const HomeWidgetCalendarCacheStorage(),
    );
final getAndroidWidgetCalendarCacheUsecaseProvider =
    Provider<GetAndroidWidgetCalendarCacheUsecase>(
      (ref) => GetAndroidWidgetCalendarCacheUsecase(
        events: ref.watch(calendarEventQueryServiceProvider),
        labels: ref.watch(calendarLabelQueryServiceProvider),
        groups: ref.watch(groupQueryServiceProvider),
        expander: ref.watch(calendarRecurrenceExpanderProvider),
        mode: ref.watch(appModeProvider),
        currentUser: ref.watch(appModeProvider) == AppMode.online
            ? ref.watch(authServiceProvider)
            : null,
      ),
    );

final refreshCalendarWidgetProvider =
    Provider<Future<void> Function(DateTime?)>((ref) {
      var generation = 0;
      Future<void> pending = Future.value();
      return (date) async {
        if (!ref.read(calendarWidgetSupportedProvider)) return;
        if (!(await ref.read(
          loadInstalledAndroidWidgetKindsProvider,
        )()).contains(AndroidWidgetKind.calendar)) {
          return;
        }
        final request = ++generation;
        final storage = ref.read(calendarWidgetCacheStorageProvider);
        Future<void> refresh() async {
          if (!ref.mounted || request != generation) return;
          final previousScope = await storage.loadScope();
          final selectionUsecase = ref.read(
            getCalendarWidgetSelectionUsecaseProvider,
          );
          final selection = await selectionUsecase.execute();
          if (!ref.mounted || request != generation) return;
          if (selection == null) {
            await storage.clear();
            await storage.update();
            return;
          }
          if (!await storage.setScopeIfCurrent(
            previousScope,
            selection.cacheScope,
          )) {
            return;
          }
          if (!ref.mounted || request != generation) return;
          final usecase = ref.read(
            getAndroidWidgetCalendarCacheUsecaseProvider,
          );
          final clock = ref.read(appClockProvider);
          final month =
              date ??
              await storage.loadSelectedDate() ??
              await storage.loadMonth() ??
              clock.now();
          await storage.refresh(selection.cacheScope, month, () async {
            final cache = await usecase.execute(
              selection.visibleGroupIds,
              month,
              ownerId: selection.ownerId,
            );
            final latest = await selectionUsecase.execute();
            if (!ref.mounted || request != generation) return;
            if (latest?.cacheScope != selection.cacheScope) {
              await storage.setScopeIfCurrent(
                selection.cacheScope,
                latest?.cacheScope,
              );
              return;
            }
            if (await storage.loadScope() != selection.cacheScope) return;
            if (cache == null) return;
            await storage.save({
              ...cache,
              'lastUpdatedAt': clock.now().toIso8601String(),
            }, merge: date != null);
          });
        }

        final previous = pending;
        Future<void> run() async {
          try {
            await previous;
          } catch (_) {}
          await storage.synchronize(refresh);
        }

        final result = run();
        pending = result;
        await result;
      };
    });
