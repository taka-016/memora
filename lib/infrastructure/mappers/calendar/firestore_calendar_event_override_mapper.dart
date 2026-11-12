import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

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
    Duration parentDuration = Duration.zero,
  }) {
    final start = normalize(value.originalStartDateTime, parentAllDay);
    return {
      'eventId': eventId,
      'groupId': groupId,
      'originalStartDateTime': Timestamp.fromDate(start),
      'originalEndDateTime': Timestamp.fromDate(start.add(parentDuration)),
      'isCancelled': true,
    };
  }

  static CalendarEventOverride fromFirestore(
    Map<String, dynamic> data, {
    required bool parentAllDay,
  }) {
    if (data['isCancelled'] != true) {
      throw ValidationException('旧形式の個別変更は移行が必要です');
    }
    final start = (data['originalStartDateTime'] as Timestamp).toDate();
    return CalendarEventOverride(
      originalStartDateTime: parentAllDay ? start.toUtc() : start,
    );
  }
}
