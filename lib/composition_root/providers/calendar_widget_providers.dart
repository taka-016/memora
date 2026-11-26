import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/composition_root/providers/shared_calendar_cache_providers.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_label_query_service.dart';
import 'package:memora/infrastructure/services/shared_calendar_widget_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/android_widget/get_calendar_widget_selection_usecase.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/factories/auth_service_factory.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/composition_root/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

final getCalendarWidgetSelectionUsecaseProvider =
    Provider<GetCalendarWidgetSelectionUsecase>(
      (ref) => GetCalendarWidgetSelectionUsecase(
        mode: ref.watch(appModeProvider),
        currentMember: ref.watch(getCurrentMemberUsecaseProvider),
        groups: ref.watch(groupQueryServiceProvider),
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
    Provider<GetAndroidWidgetCalendarCacheUsecase>((ref) {
      final mode = ref.watch(appModeProvider);
      SharedCalendarWidgetData? shared;
      if (mode == AppMode.online) {
        final firestore = ref.watch(firebaseFirestoreProvider);
        const server = GetOptions(source: Source.server);
        shared = SharedCalendarWidgetData(
          cache: ref.watch(sharedCalendarCacheProvider),
          currentOwnerId: ref.watch(onlineCalendarCacheOwnerProvider),
          fetchEvents: FirestoreCalendarEventQueryService(
            firestore: firestore,
            options: server,
          ).getCalendarEventsForWidget,
          fetchLabels: FirestoreCalendarLabelQueryService(
            firestore: firestore,
            options: server,
          ).getCalendarLabelsByGroupId,
        );
      }
      return GetAndroidWidgetCalendarCacheUsecase(
        events: ref.watch(calendarEventQueryServiceProvider),
        labels: ref.watch(calendarLabelQueryServiceProvider),
        expander: ref.watch(calendarRecurrenceExpanderProvider),
        mode: mode,
        currentUser: mode == AppMode.online
            ? ref.watch(authServiceProvider)
            : null,
        loadSharedGroup: shared?.load,
      );
    });

typedef _RefreshCalendarWidget = Future<void> Function(
  DateTime?, {
  bool afterRestore,
  bool force,
  bool afterMutation,
  bool moveToToday,
});

final refreshCalendarWidgetProvider = Provider<_RefreshCalendarWidget>((ref) {
  var generation = 0;
  var discardPreviousMonths = false;
  var forceRequested = false;
  var redrawPublishedMonths = false;
  var refreshLabels = false;
  Future<void> pending = Future.value();
  return (
    date, {
    afterRestore = false,
    force = false,
    afterMutation = false,
    moveToToday = false,
  }) async {
    if (!ref.read(calendarWidgetSupportedProvider)) return;
    if (!(await ref.read(
      loadInstalledAndroidWidgetKindsProvider,
    )()).contains(AndroidWidgetKind.calendar)) {
      return;
    }
    if (afterRestore) discardPreviousMonths = true;
    if (afterMutation) {
      redrawPublishedMonths = true;
      if (force) refreshLabels = true;
    } else if (force) {
      forceRequested = true;
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
      final usecase = ref.read(getAndroidWidgetCalendarCacheUsecaseProvider);
      final clock = ref.read(appClockProvider);
      DateTime? today;
      if (moveToToday) {
        final now = clock.now();
        today = DateTime(now.year, now.month, now.day);
        await storage.selectDateForAllWidgets(selection.cacheScope, today);
      }
      final month =
          today ??
          date ??
          await storage.loadSelectedDate() ??
          await storage.loadMonth() ??
          clock.now();
      final publishedMonths = redrawPublishedMonths && !discardPreviousMonths
          ? await storage.loadPublishedMonths(selection.cacheScope)
          : const <DateTime>[];
      await storage.refresh(selection.cacheScope, month, () async {
        final cache = await usecase.execute(
          selection.visibleGroups,
          month,
          ownerId: selection.ownerId,
          force: forceRequested,
          forceLabels: refreshLabels,
          publishedMonths: publishedMonths,
        );
        final latestScope = await selectionUsecase.loadCurrentScope();
        if (!ref.mounted || request != generation) return;
        if (latestScope != selection.cacheScope) {
          await storage.setScopeIfCurrent(selection.cacheScope, latestScope);
          return;
        }
        if (await storage.loadScope() != selection.cacheScope) return;
        if (cache == null) return;
        final synchronized = cache['synchronized'] != false;
        final now = clock.now().toIso8601String();
        await storage.save(
          {
            ...cache,
            'lastUpdatedAt':
                cache['lastUpdatedAt'] ?? (synchronized ? now : ''),
            if (synchronized) 'synchronizedAt': now,
          },
          retainMonthsWithin: discardPreviousMonths
              ? 0
              : (date == null && !redrawPublishedMonths ? 2 : null),
        );
        if (request == generation) {
          discardPreviousMonths = false;
          forceRequested = false;
          redrawPublishedMonths = false;
          refreshLabels = false;
        }
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
