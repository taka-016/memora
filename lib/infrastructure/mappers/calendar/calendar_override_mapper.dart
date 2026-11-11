import 'package:memora/domain/entities/calendar/calendar_event_override.dart';

class CalendarOverrideMapper {
  static DateTime date(DateTime value, bool allDay) =>
      allDay ? DateTime.utc(value.year, value.month, value.day) : value;
  static Map<String, Object?> toRow(
    CalendarEventOverride value,
    String eventId,
    String groupId,
    bool parentAllDay, {
    Duration parentDuration = Duration.zero,
  }) {
    final start = date(value.originalStartDateTime, parentAllDay);
    return {
      'event_id': eventId,
      'group_id': groupId,
      'original_start_date_time': start.microsecondsSinceEpoch,
      'original_end_date_time': start
          .add(parentDuration)
          .microsecondsSinceEpoch,
      'is_cancelled': 1,
    };
  }

  static CalendarEventOverride fromRow(
    Map<String, Object?> row,
    bool parentAllDay,
  ) => CalendarEventOverride(
    originalStartDateTime: DateTime.fromMicrosecondsSinceEpoch(
      row['original_start_date_time'] as int,
      isUtc: parentAllDay,
    ),
  );
}
