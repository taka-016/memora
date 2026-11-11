import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/models/calendar_event_period.dart';

List<Query<Map<String, dynamic>>> calendarEventQueries(
  FirebaseFirestore firestore,
  String groupId,
  CalendarEventPeriod? period,
) {
  final base = firestore
      .collection('calendar_events')
      .where('groupId', isEqualTo: groupId);
  if (period == null) return [base];
  return [
    base
        .where('recurrenceRule', isNull: true)
        .where(
          'endDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
        )
        .where('startDateTime', isLessThan: Timestamp.fromDate(period.queryTo)),
    base
        .where('recurrenceRule', isNull: false)
        .where(
          'recurrenceEndDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
        )
        .where('startDateTime', isLessThan: Timestamp.fromDate(period.queryTo)),
  ];
}
