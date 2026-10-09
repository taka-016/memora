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
      recurrenceRule: data['recurrenceRule'] as String?,
      timeZone: data['timeZone'] as String?,
      overrides: overrides,
      id: doc.id,
      groupId: data['groupId'] as String,
      labelId: data['labelId'] as String,
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
    'recurrenceRule': value.recurrenceRule,
    'timeZone': value.timeZone,
    'referencedLabelIds': {
      value.labelId,
      ...value.overrides.where((v) => !v.isCancelled).map((v) => v.labelId!),
    }.toList(),
    'groupId': value.groupId,
    'labelId': value.labelId,
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
    'isAllDay': value.isAllDay,
  };
  static Map<String, dynamic> toCreateFirestore(CalendarEvent value) => {
    ...toFirestore(value),
    ...FirestoreWriteMetadata.forCreate(),
  };
  static Map<String, dynamic> toUpdateFirestore(CalendarEvent value) => {
    ...toFirestore(value),
    ...FirestoreWriteMetadata.forUpdate(),
  };
}
