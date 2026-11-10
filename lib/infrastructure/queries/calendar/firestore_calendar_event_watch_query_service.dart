import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_queries.dart';
import 'package:memora/application/models/calendar_event_period.dart';

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
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) {
    final queries = calendarEventQueries(firestore, groupId, period);
    final received = List<Map<String, Future<CalendarEventDto>>?>.filled(
      queries.length,
      null,
      growable: true,
    );
    final store = FirestoreCalendarEventStore(firestore);
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    var generation = 0;
    var cancelled = false;
    late StreamController<List<CalendarEventDto>> controller;
    controller = StreamController<List<CalendarEventDto>>(
      onListen: () {
        for (var index = 0; index < queries.length; index++) {
          final bucket = index;
          subscriptions.add(
            queries[index].snapshots().listen(
              (snapshot) async {
                final current = ++generation;
                try {
                  final pending =
                      received[bucket] ?? <String, Future<CalendarEventDto>>{};
                  for (final change in snapshot.docChanges) {
                    if (change.type == DocumentChangeType.removed) {
                      pending.remove(change.doc.id);
                    } else {
                      pending[change.doc.id] = store.read(change.doc);
                    }
                  }
                  received[bucket] = pending;
                  await Future.wait(pending.values);
                  if (cancelled) return;
                  if (received.any((value) => value == null)) return;
                  final combined = <String, Future<CalendarEventDto>>{
                    for (final values in received) ...values!,
                  };
                  final events = await Future.wait(combined.values);
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
            ),
          );
        }
      },
      onCancel: () async {
        cancelled = true;
        generation++;
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
        received.clear();
      },
    );
    return controller.stream;
  }
}
