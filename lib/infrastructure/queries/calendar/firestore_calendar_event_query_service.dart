import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_queries.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';

class FirestoreCalendarEventQueryService implements CalendarEventQueryService {
  FirestoreCalendarEventQueryService({required this._firestore});
  final FirebaseFirestore _firestore;
  @override
  Future<CalendarEventDto?> getCalendarEventById(String eventId) async {
    final doc = await _firestore
        .collection('calendar_events')
        .doc(eventId)
        .get();
    return doc.exists
        ? FirestoreCalendarEventStore(_firestore).read(doc)
        : null;
  }

  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) async {
    final snapshots = await Future.wait(
      calendarEventQueries(
        _firestore,
        groupId,
        period,
      ).map((query) => query.get()),
    );
    final docs = {
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs) doc.id: doc,
    };
    final store = FirestoreCalendarEventStore(_firestore);
    return Future.wait(
      docs.values.map((doc) => store.read(doc, period: period)),
    );
  }
}
