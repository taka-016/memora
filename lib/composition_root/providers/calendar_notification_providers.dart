import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/application/services/calendar/calendar_notification_source.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';
import 'package:memora/application/usecases/calendar/synchronize_calendar_notifications_usecase.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/calendar_notification_source.dart';
import 'package:memora/infrastructure/services/local_calendar_notification_gateway.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_notification_storage.dart';

final calendarNotificationStorageProvider =
    Provider<CalendarNotificationStorage>(
      (ref) => const SharedPreferencesCalendarNotificationStorage(),
    );
final calendarNotificationGatewayProvider =
    Provider<CalendarNotificationGateway>(
      (ref) => LocalCalendarNotificationGateway(),
    );
final calendarNotificationSourceProvider = Provider<CalendarNotificationSource>(
  (ref) => DeviceCalendarNotificationSource(
    currentMember: ref.watch(getCurrentMemberUsecaseProvider),
    groups: ref.watch(getGroupsWithMembersUsecaseProvider),
    events: ref.watch(getCalendarEventsUsecaseProvider),
    database: ref.watch(appModeProvider) == AppMode.offline
        ? ref.watch(offlineDatabaseProvider)
        : null,
    firestore: ref.watch(appModeProvider) == AppMode.online
        ? ref.watch(firebaseFirestoreProvider)
        : null,
  ),
);
final synchronizeCalendarNotificationsUsecaseProvider =
    Provider<SynchronizeCalendarNotificationsUsecase>(
      (ref) => SynchronizeCalendarNotificationsUsecase(
        loadEvents: ref.watch(calendarNotificationSourceProvider).load,
        storage: ref.watch(calendarNotificationStorageProvider),
        gateway: ref.watch(calendarNotificationGatewayProvider),
        planner: CalendarNotificationPlanner(
          ref.watch(calendarRecurrenceExpanderProvider),
        ),
        now: ref.watch(appClockProvider).now,
      ),
    );

final calendarNotificationsSupportedProvider = Provider<bool>(
  (ref) => Platform.isAndroid,
);
