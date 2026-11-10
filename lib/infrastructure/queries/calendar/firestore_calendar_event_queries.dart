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
        .where(
          'endDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
        )
        .where('startDateTime', isLessThan: Timestamp.fromDate(period.queryTo)),
    // 個別回の日時変更で期間内に入る系列も取得する。
    base.where('recurrenceRule', isNull: false),
  ];
}
