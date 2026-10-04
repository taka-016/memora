import 'package:memora/domain/entities/calendar/calendar_event_override.dart';

class CalendarOverrideMapper {
  static DateTime date(DateTime value, bool allDay) =>
      allDay ? DateTime.utc(value.year, value.month, value.day) : value;
  static Map<String, Object?> toRow(
    CalendarEventOverride value,
    String eventId,
    String groupId,
    bool parentAllDay,
  ) => {
    'event_id': eventId,
    'group_id': groupId,
    'original_start_date_time': date(
      value.originalStartDateTime,
      parentAllDay,
    ).microsecondsSinceEpoch,
    'is_cancelled': value.isCancelled ? 1 : 0,
    'title': value.title,
    'start_date_time': value.startDateTime == null
        ? null
        : date(value.startDateTime!, value.isAllDay!).microsecondsSinceEpoch,
    'end_date_time': value.endDateTime == null
        ? null
        : date(value.endDateTime!, value.isAllDay!).microsecondsSinceEpoch,
    'is_all_day': value.isAllDay == null ? null : (value.isAllDay! ? 1 : 0),
    'label_id': value.labelId,
  };
  static CalendarEventOverride fromRow(
    Map<String, Object?> row,
    bool parentAllDay,
  ) => CalendarEventOverride(
    originalStartDateTime: DateTime.fromMicrosecondsSinceEpoch(
      row['original_start_date_time'] as int,
      isUtc: parentAllDay,
    ),
    isCancelled: row['is_cancelled'] == 1,
    title: row['title'] as String?,
    startDateTime: row['start_date_time'] == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(
            row['start_date_time'] as int,
            isUtc: row['is_all_day'] == 1,
          ),
    endDateTime: row['end_date_time'] == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(
            row['end_date_time'] as int,
            isUtc: row['is_all_day'] == 1,
          ),
    isAllDay: row['is_all_day'] == null ? null : row['is_all_day'] == 1,
    labelId: row['label_id'] as String?,
  );
}
