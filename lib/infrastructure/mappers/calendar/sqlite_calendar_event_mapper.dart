import 'dart:convert';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

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
    overridesFingerprint: row['overrides_fingerprint'] as String?,
    groupId: row['group_id'] as String,
    labelId: row['label_id'] as String? ?? '',
    labelType: row['label_type'] as String,
    memberId: row['member_id'] as String? ?? '',
    notificationMinutesBefore: (jsonDecode(
      row['notification_minutes_before'] as String,
    ) as List).cast<int>(),
    url: row['url'] as String? ?? '',
    memo: row['memo'] as String? ?? '',
    locationName: row['location_name'] as String? ?? '',
    latitude: (row['latitude'] as num?)?.toDouble(),
    longitude: (row['longitude'] as num?)?.toDouble(),
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
    'recurrence_end_date_time': CalendarRecurrenceExpander(IanaCalendarTimeZone()).seriesEndDateTime(CalendarEventMapper.toDto(value))?.microsecondsSinceEpoch,
    'overrides_fingerprint': jsonEncode(value.overrides.map((v) => (value.isAllDay ? DateTime.utc(v.originalStartDateTime.year, v.originalStartDateTime.month, v.originalStartDateTime.day) : v.originalStartDateTime).microsecondsSinceEpoch).toList()..sort()),
    'time_zone': value.timeZone,
    'id': value.id,
    'group_id': value.groupId,
    'label_id': value.labelType == 'custom' ? value.labelId : null,
    'label_type': value.labelType,
    'member_id': value.labelType == 'member' ? value.memberId : null,
    'url': value.url,
    'memo': value.memo,
    'location_name': value.locationName,
    'latitude': value.latitude,
    'longitude': value.longitude,
    'title': value.title,
    'notification_minutes_before': jsonEncode(value.notificationMinutesBefore),
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
