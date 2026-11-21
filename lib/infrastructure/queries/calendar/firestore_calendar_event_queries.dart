import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/models/calendar_event_period.dart';

List<Query<Map<String, dynamic>>> calendarEventQueries(
  FirebaseFirestore firestore,
  String groupId,
  CalendarEventPeriod? period,
) {
  final base = calendarEventGroupQuery(firestore, groupId);
  if (period == null) return [base];
  return [
    calendarSingleEventQuery(base, period),
    calendarEventPeriodQuery(
      base.where('recurrenceRule', isNull: false),
      period,
      startField: 'startDateTime',
      endField: 'recurrenceEndDateTime',
    ).orderBy('recurrenceRule'),
  ];
}

Query<Map<String, dynamic>> calendarEventGroupQuery(
  FirebaseFirestore firestore,
  String groupId,
) => firestore
    .collection('calendar_events')
    .where('groupId', isEqualTo: groupId);

Query<Map<String, dynamic>> calendarSingleEventQuery(
  Query<Map<String, dynamic>> base,
  CalendarEventPeriod period,
) => calendarEventPeriodQuery(
  base.where('recurrenceRule', isNull: true),
  period,
  startField: 'startDateTime',
  endField: 'endDateTime',
);

Query<Map<String, dynamic>> calendarEventPeriodQuery(
  Query<Map<String, dynamic>> base,
  CalendarEventPeriod period, {
  required String startField,
  required String endField,
}) {
  final minimum = DateTime.utc(1);
  final from = period.queryFrom;
  final to = period.queryTo;
  var query = base.where(
    endField,
    isGreaterThanOrEqualTo: Timestamp.fromDate(
      from.isBefore(minimum) ? minimum : from,
    ),
  );
  // Firestoreに保存できる日時はすべて西暦10000年より前。
  if (to.isBefore(DateTime.utc(10000))) {
    query = query.where(startField, isLessThan: Timestamp.fromDate(to));
  }
  return query.orderBy(endField).orderBy(startField);
}
