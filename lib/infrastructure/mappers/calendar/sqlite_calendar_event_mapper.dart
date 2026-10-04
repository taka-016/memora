import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';

class SqliteCalendarEventMapper {
  static CalendarEventDto fromRow(
    Map<String, Object?> row, {
    List<CalendarEventOverride> overrides = const [],
  }) => CalendarEventDto(
    recurrenceRule: row['recurrence_rule'] as String?,
    timeZone: row['time_zone'] as String?,
    overrides: overrides,
    id: row['id'] as String,
    groupId: row['group_id'] as String,
    labelId: row['label_id'] as String,
    title: row['title'] as String,
    startDateTime: DateTime.fromMicrosecondsSinceEpoch(
      row['start_date_time'] as int,
      isUtc: row['is_all_day'] == 1,
    ),
    endDateTime: DateTime.fromMicrosecondsSinceEpoch(
      row['end_date_time'] as int,
      isUtc: row['is_all_day'] == 1,
    ),
    isAllDay: row['is_all_day'] == 1,
  );
  static Map<String, Object?> toRow(CalendarEvent value) => {
    'recurrence_rule': value.recurrenceRule,
    'time_zone': value.timeZone,
    'id': value.id,
    'group_id': value.groupId,
    'label_id': value.labelId,
    'title': value.title,
    'start_date_time':
        (value.isAllDay
                ? DateTime.utc(
                    value.startDateTime.year,
                    value.startDateTime.month,
                    value.startDateTime.day,
                  )
                : value.startDateTime)
            .microsecondsSinceEpoch,
    'end_date_time':
        (value.isAllDay
                ? DateTime.utc(
                    value.endDateTime.year,
                    value.endDateTime.month,
                    value.endDateTime.day,
                  )
                : value.endDateTime)
            .microsecondsSinceEpoch,
    'is_all_day': value.isAllDay ? 1 : 0,
  };
}
