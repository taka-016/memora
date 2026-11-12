import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';

void main() {
  test('終日の検索終了境界は入力時刻によらず暦日による期間を使う', () {
    final event = CalendarEvent(
      id: 'e',
      groupId: 'g',
      labelType: 'group',
      title: '予定',
      startDateTime: DateTime.utc(2026, 1, 1, 12),
      endDateTime: DateTime.utc(2026, 1, 3),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;COUNT=3',
    );
    expect(
      FirestoreCalendarEventMapper.toFirestore(event)['calendarFormatVersion'],
      2,
    );
    expect(
      FirestoreCalendarEventMapper.toFirestore(event)['recurrenceEndDateTime'],
      Timestamp.fromDate(DateTime.utc(2026, 1, 5)),
    );
  });
  for (final definition in [
    (
      rule: 'FREQ=DAILY;COUNT=3',
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2026, 1, 5),
      allDay: true,
      zone: null,
    ),
    (
      rule: 'FREQ=MONTHLY;BYDAY=5MO;COUNT=3',
      start: DateTime.utc(2026, 3, 30),
      end: DateTime.utc(2026, 9, 2),
      allDay: true,
      zone: null,
    ),
    (
      rule: 'FREQ=DAILY;COUNT=3',
      start: DateTime.utc(2026, 3, 7, 7, 30),
      end: DateTime.utc(2026, 3, 12, 6, 30),
      allDay: false,
      zone: 'America/New_York',
    ),
    (
      rule: 'FREQ=DAILY;UNTIL=20260103',
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2026, 1, 5),
      allDay: true,
      zone: null,
    ),
  ]) {
    test('期間検索用の系列終了境界は最終回の終了を含む（${definition.rule}・${definition.zone}）', () {
      final event = CalendarEvent(
        id: 'e',
        groupId: 'g',
        labelType: 'group',
        title: '予定',
        startDateTime: definition.start,
        endDateTime: definition.start.add(const Duration(days: 2)),
        isAllDay: definition.allDay,
        recurrenceRule: definition.rule,
        timeZone: definition.zone,
      );
      expect(
        FirestoreCalendarEventMapper.toFirestore(
          event,
        )['recurrenceEndDateTime'],
        Timestamp.fromDate(definition.end),
      );
    });
  }
}
