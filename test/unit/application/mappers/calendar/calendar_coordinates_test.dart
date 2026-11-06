import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/mappers/calendar/calendar_override_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_override_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';
import 'package:memora/infrastructure/services/calendar_event_content.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

void main() {
  test('通常予定と個別回の座標を保存形式・競合比較・発生日への展開でも保持する', () {
    final override = CalendarEventOverride(
      originalStartDateTime: DateTime.utc(2026, 11, 7),
      isCancelled: false,
      title: '変更後',
      labelId: 'label',
      startDateTime: DateTime.utc(2026, 11, 7),
      endDateTime: DateTime.utc(2026, 11, 8),
      isAllDay: true,
      latitude: 34.0,
      longitude: 135.0,
    );
    final dto = CalendarEventDto(
      id: 'event', groupId: 'group', labelId: 'label', title: '予定',
      startDateTime: DateTime.utc(2026, 11, 6),
      endDateTime: DateTime.utc(2026, 11, 7), isAllDay: true,
      latitude: 35.0, longitude: 139.0,
      recurrenceRule: 'FREQ=DAILY;COUNT=2', overrides: [override],
    );
    final entity = CalendarEventMapper.toEntity(dto);
    final row = SqliteCalendarEventMapper.toRow(entity);
    final restored = SqliteCalendarEventMapper.fromRow(row);
    expect(restored.latitude, 35.0);
    expect(restored.longitude, 139.0);
    final document = FirestoreCalendarEventMapper.toFirestore(entity);
    expect(document['latitude'], 35.0);
    expect(document['longitude'], 139.0);
    final overrideRow = CalendarOverrideMapper.toRow(override, 'event', 'group', true);
    expect(CalendarOverrideMapper.fromRow(overrideRow, true), override);
    final overrideDoc = FirestoreCalendarEventOverrideMapper.toFirestore(
      override, eventId: 'event', groupId: 'group', parentAllDay: true,
    );
    expect(FirestoreCalendarEventOverrideMapper.fromFirestore(overrideDoc, parentAllDay: true), override);
    expect(calendarEventContent(entity).overrides.single, override);
    final events = CalendarRecurrenceExpander(IanaCalendarTimeZone()).expand(
      dto, DateTime.utc(2026, 11, 6), DateTime.utc(2026, 11, 8),
    );
    expect(events.map((v) => v.latitude), [35.0, 34.0]);
    expect(events.map((v) => v.longitude), [139.0, 135.0]);
  });
}
