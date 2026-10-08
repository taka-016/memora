import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';

typedef _EventReadResult = ({
  CalendarEventDto? event,
  ValidationException? error,
});

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
      snapshot.docs.map((doc) async {
        final result = await _firestore.runTransaction<_EventReadResult>((
          transaction,
        ) async {
          final current = await transaction.get(
            _firestore.collection('calendar_events').doc(doc.id),
          );
          if (!current.exists) return (event: null, error: null);
          try {
            return (
              event: await store.read(current, transaction: transaction),
              error: null,
            );
          } on ValidationException catch (error) {
            // SDKの読取バージョン照合による競合再試行を終えてから欠損を拒否する。
            return (event: null, error: error);
          }
        });
        if (result.error != null) throw result.error!;
        return result.event;
      }),
    );
    return events.whereType<CalendarEventDto>().toList();
  }
}
