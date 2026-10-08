import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';

class FirestoreCalendarEventQueryService implements CalendarEventQueryService {
  FirestoreCalendarEventQueryService({required this._firestore});
  final FirebaseFirestore _firestore;
  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(
    String groupId,
  ) async {
    final snapshot = await _firestore
        .collection('calendar_events')
        .where('groupId', isEqualTo: groupId)
        .get();
    final store = FirestoreCalendarEventStore(_firestore);
    final events = await Future.wait(
      snapshot.docs.map(
        (doc) =>
            _firestore.runTransaction<CalendarEventDto?>((transaction) async {
              final current = await transaction.get(
                _firestore.collection('calendar_events').doc(doc.id),
              );
              if (!current.exists) return null;
              return await store.read(current, transaction: transaction);
            }),
      ),
    );
    return events.whereType<CalendarEventDto>().toList();
  }
}
