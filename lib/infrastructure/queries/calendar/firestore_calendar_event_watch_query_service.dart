import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_queries.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';

typedef _EventDocument = DocumentSnapshot<Map<String, dynamic>>;
typedef _EventDocuments = Map<String, _EventDocument>;
typedef _EventRead = (_EventDocument, Future<CalendarEventDto>);

class FirestoreCalendarEventWatchQueryService
    implements CalendarEventWatchQueryService, CalendarEventQueryService {
  FirestoreCalendarEventWatchQueryService({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Future<CalendarEventDto?> getCalendarEventById(String eventId) =>
      FirestoreCalendarEventQueryService(firestore: firestore)
          .getCalendarEventById(eventId);

  final _active =
      <
        (String, CalendarEventPeriod?, bool),
        _SharedEvents<List<CalendarEventDto>>
      >{};
  final _recurringParents = <String, _SharedEvents<_EventDocuments>>{};

  _SharedEvents<List<CalendarEventDto>>? _covering(
    String groupId,
    CalendarEventPeriod? period, {
    bool allRecurringParents = false,
  }) {
    for (final entry in _active.entries) {
      final (id, range, sharesRecurringParents) = entry.key;
      if (id == groupId &&
          (!allRecurringParents || sharesRecurringParents) &&
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
  }) => _watchShared(groupId, period, allRecurringParents: false);

  Stream<List<CalendarEventDto>> watchCalendarScreenEvents(
    String groupId, {
    CalendarEventPeriod? period,
  }) => _watchShared(groupId, period, allRecurringParents: true);

  Stream<List<CalendarEventDto>> _watchShared(
    String groupId,
    CalendarEventPeriod? period, {
    required bool allRecurringParents,
  }) {
    // 購読時に共有先を決め、生成しただけのStreamは保持しない。
    late StreamController<List<CalendarEventDto>> controller;
    StreamSubscription<List<CalendarEventDto>>? subscription;
    controller = StreamController<List<CalendarEventDto>>(
      onListen: () {
        final key = (groupId, period, allRecurringParents);
        var shared = _covering(
          groupId,
          period,
          allRecurringParents: allRecurringParents,
        );
        if (shared == null) {
          final created = _SharedEvents(
            () => _watch(
              groupId,
              period: period,
              allRecurringParents: allRecurringParents,
            ),
          );
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

  Stream<_EventDocuments> _watchDocuments(Query<Map<String, dynamic>> query) {
    final documents = <String, _EventDocument>{};
    return query.snapshots().map((snapshot) {
      for (final change in snapshot.docChanges) {
        final document = change.doc;
        if (change.type == DocumentChangeType.removed) {
          documents.remove(document.id);
        } else {
          documents[document.id] = document;
        }
      }
      return Map.of(documents);
    });
  }

  Stream<_EventDocuments> _watchRecurringParents(String groupId) {
    final shared = _recurringParents.putIfAbsent(groupId, () {
      final created = _SharedEvents(
        () => _watchDocuments(
          calendarEventGroupQuery(
            firestore,
            groupId,
          ).where('recurrenceRule', isNull: false),
        ),
        retryOnListen: true,
      );
      created.onEmpty = () => _recurringParents.remove(groupId);
      return created;
    });
    return shared.stream;
  }

  bool _overlapsPeriod(_EventDocument document, CalendarEventPeriod period) {
    final data = document.data()!;
    final end = data['recurrenceEndDateTime'] as Timestamp?;
    final start = data['startDateTime'] as Timestamp;
    return end != null &&
        !end.toDate().isBefore(period.queryFrom) &&
        start.toDate().isBefore(period.queryTo);
  }

  Stream<List<CalendarEventDto>> _watch(
    String groupId, {
    required CalendarEventPeriod? period,
    required bool allRecurringParents,
  }) {
    final sources = allRecurringParents && period != null
        ? [
            _watchDocuments(
              calendarSingleEventQuery(
                calendarEventGroupQuery(firestore, groupId),
                period,
              ),
            ),
            _watchRecurringParents(groupId).map(
              (parents) => {
                for (final entry in parents.entries)
                  if (_overlapsPeriod(entry.value, period))
                    entry.key: entry.value,
              },
            ),
          ]
        : calendarEventQueries(
            firestore,
            groupId,
            period,
          ).map(_watchDocuments).toList();
    final received = List<Map<String, _EventRead>?>.filled(
      sources.length,
      null,
    );
    final store = FirestoreCalendarEventStore(firestore);
    final subscriptions = <StreamSubscription<_EventDocuments>>[];
    var generation = 0;
    var cancelled = false;
    late StreamController<List<CalendarEventDto>> controller;
    controller = StreamController<List<CalendarEventDto>>(
      onListen: () {
        for (var index = 0; index < sources.length; index++) {
          final bucket = index;
          subscriptions.add(
            sources[index].listen(
              (documents) async {
                final current = ++generation;
                try {
                  final previous = received[bucket];
                  final pending = <String, _EventRead>{};
                  for (final entry in documents.entries) {
                    final existing = previous?[entry.key];
                    pending[entry.key] =
                        existing != null && identical(existing.$1, entry.value)
                        ? existing
                        : (
                            entry.value,
                            store.read(entry.value, period: period),
                          );
                  }
                  received[bucket] = pending;
                  await Future.wait(pending.values.map((entry) => entry.$2));
                  if (cancelled || received.any((value) => value == null)) {
                    return;
                  }
                  final combined = {for (final values in received) ...values!};
                  final events = await Future.wait(
                    combined.values.map((entry) => entry.$2),
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
        received.fillRange(0, received.length, null);
      },
    );
    return controller.stream;
  }
}

class _SharedEvents<T extends Object> {
  _SharedEvents(this.source, {this.retryOnListen = false});
  final Stream<T> Function() source;
  final bool retryOnListen;
  late final void Function() onEmpty;
  final _listeners = <StreamController<T>>{};
  StreamSubscription<T>? _subscription;
  T? _latest;
  Object? _error;
  StackTrace? _stack;

  Stream<T> get stream {
    late StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        _listeners.add(controller);
        if (_error != null && retryOnListen) {
          unawaited(_subscription?.cancel());
          _subscription = null;
          _latest = null;
          _error = null;
        }
        if (_error != null) {
          controller.addError(_error!, _stack);
        } else if (_latest != null) {
          controller.add(_latest!);
        }
        _subscription ??= source().listen(
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
            if (!retryOnListen) onEmpty();
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
