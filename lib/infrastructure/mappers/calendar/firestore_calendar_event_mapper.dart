import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreCalendarEventMapper {
  static CalendarEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CalendarEventDto(
      recurrenceRule: data['recurrenceRule'] as String?,
      timeZone: data['timeZone'] as String?,
      overrides: [
        for (final entry in (data['overrides'] as Map? ?? {}).entries)
          for (final raw in entry.value as List)
            _override(
              Map<String, dynamic>.from(raw as Map),
              entry.key as String,
              data['isAllDay'] as bool,
            ),
        for (final raw in data['cancelledOccurrences'] as List? ?? [])
          CalendarEventOverride(
            originalStartDateTime: _date(
              raw as Timestamp,
              data['isAllDay'] as bool,
            ),
            isCancelled: true,
          ),
      ],
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

  static CalendarEventOverride _override(
    Map<String, dynamic> row,
    String labelId,
    bool parentAllDay,
  ) => CalendarEventOverride(
    originalStartDateTime: _date(
      row['originalStartDateTime'] as Timestamp,
      parentAllDay,
    ),
    isCancelled: false,
    title: row['title'] as String,
    labelId: labelId,
    isAllDay: row['isAllDay'] as bool,
    startDateTime: _date(
      row['startDateTime'] as Timestamp,
      row['isAllDay'] as bool,
    ),
    endDateTime: _date(
      row['endDateTime'] as Timestamp,
      row['isAllDay'] as bool,
    ),
  );
  static DateTime _normalize(DateTime value, bool allDay) =>
      allDay ? DateTime.utc(value.year, value.month, value.day) : value;
  static DateTime _date(Timestamp value, bool allDay) =>
      allDay ? value.toDate().toUtc() : value.toDate();
  static Map<String, dynamic> toFirestore(CalendarEvent value) => {
    'recurrenceRule': value.recurrenceRule,
    'timeZone': value.timeZone,
    'referencedLabelIds': {
      value.labelId,
      ...value.overrides.where((v) => !v.isCancelled).map((v) => v.labelId!),
    }.toList(),
    'overrides': {
      for (final labelId
          in value.overrides
              .where((v) => !v.isCancelled)
              .map((v) => v.labelId!)
              .toSet())
        labelId: value.overrides
            .where((v) => !v.isCancelled && v.labelId == labelId)
            .map(
              (v) => {
                'originalStartDateTime': Timestamp.fromDate(
                  _normalize(v.originalStartDateTime, value.isAllDay),
                ),
                'title': v.title,
                'isAllDay': v.isAllDay,
                'startDateTime': Timestamp.fromDate(
                  _normalize(v.startDateTime!, v.isAllDay!),
                ),
                'endDateTime': Timestamp.fromDate(
                  _normalize(v.endDateTime!, v.isAllDay!),
                ),
              },
            )
            .toList(),
    },
    'cancelledOccurrences': value.overrides
        .where((v) => v.isCancelled)
        .map(
          (v) => Timestamp.fromDate(
            _normalize(v.originalStartDateTime, value.isAllDay),
          ),
        )
        .toList(),
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
