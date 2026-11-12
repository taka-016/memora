import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreCalendarEventMapper {
  static CalendarEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<CalendarEventOverride> overrides = const [],
  }) {
    final data = doc.data()!;
    return CalendarEventDto(
      version: data['version'] as int?,
      recurrenceRule: data['recurrenceRule'] as String?,
      timeZone: data['timeZone'] as String?,
      overrides: overrides,
      id: doc.id,
      groupId: data['groupId'] as String,
      labelId: data['labelId'] as String? ?? '',
      labelType: data['labelType'] as String,
      memberId: data['memberId'] as String? ?? '',
      notificationMinutesBefore:
          (data['notificationMinutesBefore'] as List? ?? const []).cast<int>(),
      url: data['url'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      locationName: data['locationName'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      title: data['title'] as String,
      startDateTime: _date(
        data['startDateTime'] as Timestamp,
        data['isAllDay'] as bool,
      ),
      endDateTime: _date(
        data['endDateTime'] as Timestamp,
        data['isAllDay'] as bool,
      ),
      isAllDay: data['isAllDay'] as bool,
    );
  }

  static DateTime _date(Timestamp value, bool allDay) =>
      allDay ? value.toDate().toUtc() : value.toDate();
  static Map<String, dynamic> toFirestore(CalendarEvent value) => {
    'calendarFormatVersion': 2,
    'recurrenceRule': value.recurrenceRule,
    'recurrenceEndDateTime': Timestamp.fromDate(
      CalendarRecurrenceExpander(IanaCalendarTimeZone())
              .seriesEndDateTime(CalendarEventMapper.toDto(value)) ??
          DateTime.utc(9999, 12, 31, 23, 59, 59),
    ),
    'timeZone': value.timeZone,
    'referencedLabelIds': {if (value.labelType == 'custom') value.labelId}
        .toList(),
    'groupId': value.groupId,
    'labelId': value.labelType == 'custom' ? value.labelId : null,
    'labelType': value.labelType,
    'memberId': value.labelType == 'member' ? value.memberId : null,
    'url': value.url,
    'memo': value.memo,
    'locationName': value.locationName,
    'latitude': value.latitude,
    'longitude': value.longitude,
    'title': value.title,
    'startDateTime': Timestamp.fromDate(
      value.isAllDay
          ? DateTime.utc(
              value.startDateTime.year,
              value.startDateTime.month,
              value.startDateTime.day,
            )
          : value.startDateTime,
    ),
    'endDateTime': Timestamp.fromDate(
      value.isAllDay
          ? DateTime.utc(
              value.endDateTime.year,
              value.endDateTime.month,
              value.endDateTime.day,
            )
          : value.endDateTime,
    ),
    'notificationMinutesBefore': value.notificationMinutesBefore,
    'isAllDay': value.isAllDay,
  };
  static Map<String, dynamic> toCreateFirestore(CalendarEvent value) => {
    ...toFirestore(value),
    'version': 1,
    ...FirestoreWriteMetadata.forCreate(),
  };
  static Map<String, dynamic> toUpdateFirestore(CalendarEvent value) => {
    ...toFirestore(value),
    'version': value.version == null ? null : value.version! + 1,
    ...FirestoreWriteMetadata.forUpdate(),
  };
}
