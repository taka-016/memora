import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';

class FirestoreCalendarEventOverrideMapper {
  static DateTime normalize(DateTime value, bool allDay) =>
      allDay ? DateTime.utc(value.year, value.month, value.day) : value.toUtc();

  static String documentId(
    String eventId,
    CalendarEventOverride value,
    bool parentAllDay,
  ) =>
      '${eventId}_${normalize(value.originalStartDateTime, parentAllDay).microsecondsSinceEpoch}';

  static Map<String, dynamic> toFirestore(
    CalendarEventOverride value, {
    required String eventId,
    required String groupId,
    required bool parentAllDay,
  }) => {
    'eventId': eventId,
    'groupId': groupId,
    'originalStartDateTime': Timestamp.fromDate(
      normalize(value.originalStartDateTime, parentAllDay),
    ),
    'isCancelled': value.isCancelled,
    'title': value.isCancelled ? null : value.title,
    'labelId': value.isCancelled ? null : value.labelId,
    'isAllDay': value.isCancelled ? null : value.isAllDay,
    'startDateTime': value.isCancelled
        ? null
        : Timestamp.fromDate(normalize(value.startDateTime!, value.isAllDay!)),
    'endDateTime': value.isCancelled
        ? null
        : Timestamp.fromDate(normalize(value.endDateTime!, value.isAllDay!)),
  };

  static CalendarEventOverride fromFirestore(
    Map<String, dynamic> data, {
    required bool parentAllDay,
  }) {
    DateTime date(String key, bool allDay) {
      final value = (data[key] as Timestamp).toDate();
      return allDay ? value.toUtc() : value;
    }

    final cancelled = data['isCancelled'] as bool;
    return CalendarEventOverride(
      originalStartDateTime: date('originalStartDateTime', parentAllDay),
      isCancelled: cancelled,
      title: cancelled ? null : data['title'] as String,
      labelId: cancelled ? null : data['labelId'] as String,
      isAllDay: cancelled ? null : data['isAllDay'] as bool,
      startDateTime: cancelled
          ? null
          : date('startDateTime', data['isAllDay'] as bool),
      endDateTime: cancelled
          ? null
          : date('endDateTime', data['isAllDay'] as bool),
    );
  }
}
