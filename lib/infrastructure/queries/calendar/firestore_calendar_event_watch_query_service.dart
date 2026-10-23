import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';

class FirestoreCalendarEventWatchQueryService
    implements CalendarEventWatchQueryService {
  FirestoreCalendarEventWatchQueryService({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(String groupId) {
    final pending = <String, Future<CalendarEventDto>>{};
    final store = FirestoreCalendarEventStore(firestore);
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
    var generation = 0;
    var cancelled = false;
    late StreamController<List<CalendarEventDto>> controller;
    controller = StreamController<List<CalendarEventDto>>(
      onListen: () {
        subscription = firestore
            .collection('calendar_events')
            .where('groupId', isEqualTo: groupId)
            .snapshots()
            .listen(
              (snapshot) async {
                final current = ++generation;
                try {
                  for (final change in snapshot.docChanges) {
                    if (change.type == DocumentChangeType.removed) {
                      pending.remove(change.doc.id);
                    } else {
                      pending[change.doc.id] = store.read(change.doc);
                    }
                  }
                  final events = await Future.wait(
                    snapshot.docs.map((doc) => pending[doc.id]!),
                  );
                  if (!cancelled && current == generation) {
                    controller.add(events);
                  }
                } catch (error, stack) {
                  if (!cancelled && current == generation) {
                    controller.addError(error, stack);
                  }
                }
              },
              onError: (Object error, StackTrace stack) {
                generation++;
                if (!cancelled) controller.addError(error, stack);
              },
            );
      },
      onCancel: () async {
        cancelled = true;
        generation++;
        await subscription?.cancel();
        pending.clear();
      },
    );
    return controller.stream;
  }
}
