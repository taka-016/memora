import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_queries.dart';
import 'package:memora/application/models/calendar_event_period.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';

class FirestoreCalendarEventWatchQueryService
    implements CalendarEventWatchQueryService, CalendarEventQueryService {
  FirestoreCalendarEventWatchQueryService({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Future<CalendarEventDto?> getCalendarEventById(String eventId) =>
      FirestoreCalendarEventQueryService(firestore: firestore).getCalendarEventById(eventId);

  final _active = <(String, CalendarEventPeriod?), _SharedEvents>{};

  _SharedEvents? _covering(String groupId, CalendarEventPeriod? period) {
    for (final entry in _active.entries) {
      final (id, range) = entry.key;
      if (id == groupId &&
          (range == null ||
              (period != null &&
                  !range.queryFrom.isAfter(period.queryFrom) &&
                  !range.queryTo.isBefore(period.queryTo)))) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) async {
    final shared = _covering(groupId, period);
    if (shared != null) return shared.stream.first;
    return FirestoreCalendarEventQueryService(firestore: firestore)
        .getCalendarEventsByGroupId(groupId, period: period);
  }

  @override
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) {
    // 購読時に共有先を決め、生成しただけのStreamは保持しない。
    late StreamController<List<CalendarEventDto>> controller;
    StreamSubscription<List<CalendarEventDto>>? subscription;
    controller = StreamController<List<CalendarEventDto>>(
      onListen: () {
        final key = (groupId, period);
        var shared = _covering(groupId, period);
        if (shared == null) {
          final created = _SharedEvents(_watch(groupId, period: period));
          created.onEmpty = () {
            if (identical(_active[key], created)) _active.remove(key);
          };
          _active[key] = shared = created;
        }
        subscription = shared.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  Stream<List<CalendarEventDto>> _watch(
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
                      pending[change.doc.id] = store.read(change.doc, period: period);
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

class _SharedEvents {
  _SharedEvents(this.source);
  final Stream<List<CalendarEventDto>> source;
  late final void Function() onEmpty;
  final _listeners = <StreamController<List<CalendarEventDto>>>{};
  StreamSubscription<List<CalendarEventDto>>? _subscription;
  List<CalendarEventDto>? _latest;
  Object? _error;
  StackTrace? _stack;

  Stream<List<CalendarEventDto>> get stream {
    late StreamController<List<CalendarEventDto>> controller;
    controller = StreamController<List<CalendarEventDto>>(
      onListen: () {
        _listeners.add(controller);
        if (_error != null) {
          controller.addError(_error!, _stack);
        } else if (_latest != null) {
          controller.add(_latest!);
        }
        _subscription ??= source.listen(
          (events) {
            _latest = events;
            _error = null;
            for (final listener in _listeners) {
              listener.add(events);
            }
          },
          onError: (Object error, StackTrace stack) {
            _error = error;
            _stack = stack;
            onEmpty();
            for (final listener in _listeners) {
              listener.addError(error, stack);
            }
          },
        );
      },
      onCancel: () async {
        _listeners.remove(controller);
        if (_listeners.isEmpty) {
          onEmpty();
          await _subscription?.cancel();
          _latest = null;
        }
      },
    );
    return controller.stream;
  }
}
