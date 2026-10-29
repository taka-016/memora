import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/calendar_override_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_override_mapper.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_notification_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final planner = CalendarNotificationPlanner(
    CalendarRecurrenceExpander(IanaCalendarTimeZone()),
  );
  final now = DateTime(2026, 10, 29, 6);
  CalendarEventDto event({
    bool allDay = true,
    List<int> reminders = const [0, 1440],
    String? rule,
    List<CalendarEventOverride> overrides = const [],
  }) => CalendarEventDto(
    id: 'event',
    groupId: 'group',
    labelType: 'group',
    title: '予定',
    startDateTime: DateTime(2026, 10, 30, 10),
    endDateTime: DateTime(2026, 10, 30, 11),
    isAllDay: allDay,
    notificationMinutesBefore: reminders,
    recurrenceRule: rule,
    timeZone: !allDay && rule != null ? 'Asia/Tokyo' : null,
    overrides: overrides,
  );
  test('終日の通知は端末の基準時刻を使い、時間指定は開始時刻から引く', () {
    final allDay = planner.plan(
      [event()],
      now,
      const CalendarNotificationPreferences(),
    );
    expect(allDay.map((v) => v.at), [
      DateTime(2026, 10, 29, 7),
      DateTime(2026, 10, 30, 7),
    ]);
    final timed = planner.plan(
      [
        event(allDay: false, reminders: [0, 60]),
      ],
      now,
      const CalendarNotificationPreferences(),
    );
    expect(timed.map((v) => v.at), [
      DateTime(2026, 10, 30, 9),
      DateTime(2026, 10, 30, 10),
    ]);
  });
  test('通知時刻が現在から4週間以内の回だけを予約し、範囲外の開始日の事前通知も含める', () {
    final source = event(rule: 'FREQ=DAILY', reminders: [10080]);
    final result = planner.plan(
      [source],
      now,
      const CalendarNotificationPreferences(),
    );
    expect(result, hasLength(28));
    expect(
      result.every(
        (v) =>
            !v.at.isBefore(now) &&
            v.at.isBefore(now.add(const Duration(days: 28))),
      ),
      isTrue,
    );
    expect(result.last.at, DateTime(2026, 11, 25, 7));
    expect(result.map((v) => v.key).toSet(), hasLength(result.length));
  });
  test('個別回の取消しと通知解除・変更を反映する', () {
    final source = event(
      rule: 'FREQ=DAILY;COUNT=3',
      reminders: [0],
      overrides: [
        CalendarEventOverride(
          originalStartDateTime: DateTime.utc(2026, 10, 30),
          isCancelled: true,
        ),
        CalendarEventOverride(
          originalStartDateTime: DateTime.utc(2026, 10, 31),
          isCancelled: false,
          title: '解除',
          startDateTime: DateTime.utc(2026, 10, 31),
          endDateTime: DateTime.utc(2026, 10, 31),
          isAllDay: true,
          labelType: 'group',
          notificationMinutesBefore: [],
        ),
      ],
    );
    expect(
      planner
          .plan([source], now, const CalendarNotificationPreferences())
          .single
          .at,
      DateTime(2026, 11, 1, 7),
    );
  });
  test('予定と個別回の通知設定をSQLiteとFirestoreへ変換し解除も保持する', () {
    final source = event();
    final entity = CalendarEventMapper.toEntity(source);
    expect(
      SqliteCalendarEventMapper.fromRow(SqliteCalendarEventMapper.toRow(entity))
          .notificationMinutesBefore,
      [0, 1440],
    );
    expect(
      FirestoreCalendarEventMapper.toFirestore(
        entity,
      )['notificationMinutesBefore'],
      [0, 1440],
    );
    final override = CalendarEventOverride(
      originalStartDateTime: now,
      isCancelled: false,
      title: '解除',
      startDateTime: now,
      endDateTime: now,
      isAllDay: true,
      labelType: 'group',
      notificationMinutesBefore: [],
    );
    expect(
      CalendarOverrideMapper.fromRow(
        CalendarOverrideMapper.toRow(override, 'event', 'group', true),
        true,
      ).notificationMinutesBefore,
      isEmpty,
    );
    final stored = FirestoreCalendarEventOverrideMapper.toFirestore(
      override,
      eventId: 'event',
      groupId: 'group',
      parentAllDay: true,
    );
    expect(
      FirestoreCalendarEventOverrideMapper.fromFirestore(
        stored,
        parentAllDay: true,
      ).notificationMinutesBefore,
      isEmpty,
    );
    expect(
      () => CalendarEventMapper.toEntity(
        event(reminders: [0, 1440, 2880, 4320, 5760, 7200]),
      ),
      throwsA(anything),
    );
    expect(
      () => CalendarEventMapper.toEntity(event(reminders: [1])),
      throwsA(anything),
    );
  });
  test('終日の初期時刻は7時で、種別ごとのデフォルトと基準時刻を端末へ保存する', () async {
    SharedPreferences.setMockInitialValues({});
    const storage = SharedPreferencesCalendarNotificationStorage();
    expect((await storage.load()).allDayMinuteOfDay, 420);
    await storage.save(
      const CalendarNotificationPreferences(
        allDayMinuteOfDay: 510,
        allDay: [1440],
        timed: [10, 60],
      ),
    );
    final loaded = await storage.load();
    expect(loaded.allDayMinuteOfDay, 510);
    expect(loaded.allDay, [1440]);
    expect(loaded.timed, [10, 60]);
  });
}
