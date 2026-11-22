import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_queries.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/infrastructure/services/firestore_calendar_event_store.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';

typedef _EventDocument = DocumentSnapshot<Map<String, dynamic>>;
typedef _EventDocuments = Map<String, _EventDocument>;
typedef _DocumentBatch = ({
  _EventDocuments documents,
  bool confirmed,
  int observedAt,
});
typedef _EventRead = (_EventDocument, Future<CalendarEventDto>);
typedef _EventBatch = ({List<CalendarEventDto> events, bool confirmed});

class FirestoreCalendarEventWatchQueryService
    implements CalendarEventWatchQueryService, CalendarEventQueryService {
  FirestoreCalendarEventWatchQueryService({
    required this.firestore,
    this.sharedCache,
    this.currentOwnerId,
  });
  final FirebaseFirestore firestore;
  final SharedCalendarCache? sharedCache;
  final String? Function()? currentOwnerId;

  @override
  Future<CalendarEventDto?> getCalendarEventById(String eventId) =>
      FirestoreCalendarEventQueryService(firestore: firestore)
          .getCalendarEventById(eventId);

  final _active =
      <
        (String?, String, CalendarEventPeriod?, bool),
        _SharedEvents<_EventBatch>
      >{};
  final _recurringParents =
      <(String?, String), _SharedEvents<_DocumentBatch>>{};

  _SharedEvents<_EventBatch>? _covering(
    String groupId,
    CalendarEventPeriod? period, {
    bool allRecurringParents = false,
    required String? ownerId,
  }) {
    for (final entry in _active.entries) {
      final (owner, id, range, sharesRecurringParents) = entry.key;
      if (owner == ownerId &&
          id == groupId &&
          allRecurringParents == sharesRecurringParents &&
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
    final shared = _covering(groupId, period, ownerId: currentOwnerId?.call());
    if (shared != null) return (await shared.stream.first).events;
    return FirestoreCalendarEventQueryService(firestore: firestore)
        .getCalendarEventsByGroupId(groupId, period: period);
  }

  @override
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) => _watchShared(
    groupId,
    period,
    allRecurringParents: false,
    ownerId: currentOwnerId?.call(),
  ).map((batch) => batch.events);

  Stream<List<CalendarEventDto>> watchCalendarScreenEvents(
    String groupId, {
    CalendarEventPeriod? period,
  }) {
    final ownerId = currentOwnerId?.call();
    final cache = sharedCache;
    final live = _watchShared(
      groupId,
      period,
      allRecurringParents: true,
      ownerId: ownerId,
    );
    if (cache == null || ownerId == null || period == null) {
      return live.map((batch) => batch.events);
    }
    return _withCachedEvents(cache, ownerId, groupId, period, live);
  }

  Stream<List<CalendarEventDto>> _withCachedEvents(
    SharedCalendarCache cache,
    String ownerId,
    String groupId,
    CalendarEventPeriod period,
    Stream<_EventBatch> live,
  ) async* {
    final cached = await cache.loadEvents(ownerId, groupId, period);
    if (currentOwnerId?.call() != ownerId) return;
    var waitingForServer = cached != null;
    if (cached != null) yield cached;

    yield* live
        .where((batch) {
          if (currentOwnerId?.call() != ownerId) return false;
          if (batch.confirmed) waitingForServer = false;
          return !waitingForServer;
        })
        .map((batch) => batch.events);
  }

  Stream<_EventBatch> _watchShared(
    String groupId,
    CalendarEventPeriod? period, {
    required bool allRecurringParents,
    required String? ownerId,
  }) {
    // 購読時に共有先を決め、生成しただけのStreamは保持しない。
    late StreamController<_EventBatch> controller;
    StreamSubscription<_EventBatch>? subscription;
    controller = StreamController<_EventBatch>(
      onListen: () {
        final key = (ownerId, groupId, period, allRecurringParents);
        var shared = _covering(
          groupId,
          period,
          allRecurringParents: allRecurringParents,
          ownerId: ownerId,
        );
        if (shared == null) {
          final created = _SharedEvents(
            () => _watch(
              groupId,
              period: period,
              allRecurringParents: allRecurringParents,
              ownerId: ownerId,
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

  Stream<_DocumentBatch> _watchDocuments(
    Query<Map<String, dynamic>> query, {
    required bool trackCoverage,
  }) {
    final documents = <String, _EventDocument>{};
    return query.snapshots(includeMetadataChanges: trackCoverage).map((
      snapshot,
    ) {
      for (final change in snapshot.docChanges) {
        final document = change.doc;
        if (change.type == DocumentChangeType.removed) {
          documents.remove(document.id);
        } else {
          documents[document.id] = document;
        }
      }
      return (
        documents: Map.of(documents),
        observedAt: trackCoverage ? DateTime.now().microsecondsSinceEpoch : 0,
        confirmed:
            !trackCoverage ||
            (!snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites),
      );
    });
  }

  Stream<_DocumentBatch> _watchRecurringParents(
    String groupId,
    String? ownerId, {
    required bool trackCoverage,
  }) {
    final key = (ownerId, groupId);
    final shared = _recurringParents.putIfAbsent(key, () {
      final created = _SharedEvents(
        () => _watchDocuments(
          calendarEventGroupQuery(
            firestore,
            groupId,
          ).where('recurrenceRule', isNull: false),
          trackCoverage: trackCoverage,
        ),
        retryOnListen: true,
      );
      created.onEmpty = () => _recurringParents.remove(key);
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

  Stream<_EventBatch> _watch(
    String groupId, {
    required CalendarEventPeriod? period,
    required bool allRecurringParents,
    required String? ownerId,
  }) {
    final cache = sharedCache;
    final persist =
        allRecurringParents &&
        period != null &&
        cache != null &&
        ownerId != null;
    final sources = allRecurringParents && period != null
        ? [
            _watchDocuments(
              calendarSingleEventQuery(
                calendarEventGroupQuery(firestore, groupId),
                period,
              ),
              trackCoverage: persist,
            ),
            _watchRecurringParents(groupId, ownerId, trackCoverage: persist),
          ]
        : calendarEventQueries(firestore, groupId, period)
              .map((query) => _watchDocuments(query, trackCoverage: false))
              .toList();
    final received = List<Map<String, _EventRead>?>.filled(
      sources.length,
      null,
    );
    final confirmed = List<bool>.filled(sources.length, false);
    final observedAt = List<int>.filled(sources.length, 0);
    final store = FirestoreCalendarEventStore(firestore);
    final subscriptions = <StreamSubscription<_DocumentBatch>>[];
    var generation = 0;
    var cancelled = false;

    late StreamController<_EventBatch> controller;
    controller = StreamController<_EventBatch>(
      onListen: () {
        for (var index = 0; index < sources.length; index++) {
          final bucket = index;
          subscriptions.add(
            sources[index].listen(
              (batch) async {
                final current = ++generation;
                try {
                  final previous = received[bucket];
                  final pending = <String, _EventRead>{};
                  for (final entry in batch.documents.entries) {
                    final old = previous?[entry.key];
                    pending[entry.key] =
                        old != null && identical(old.$1, entry.value)
                        ? old
                        : (
                            entry.value,
                            allRecurringParents
                                ? Future.sync(
                                    () => store.readForDisplay(entry.value),
                                  )
                                : store.read(entry.value, period: period),
                          );
                  }
                  received[bucket] = pending;
                  confirmed[bucket] = batch.confirmed;
                  observedAt[bucket] = batch.observedAt;
                  await Future.wait(pending.values.map((entry) => entry.$2));
                  if (cancelled ||
                      current != generation ||
                      received.any((value) => value == null)) {
                    return;
                  }
                  final combined = {for (final values in received) ...values!};
                  final entries = combined.values.toList();
                  final events = await Future.wait(
                    entries.map((entry) => entry.$2),
                  );
                  if (cancelled ||
                      current != generation ||
                      currentOwnerId?.call() != ownerId) {
                    return;
                  }
                  final complete = confirmed.every((value) => value);
                  if (persist && complete) {
                    await cache.saveEvents(
                      ownerId,
                      groupId,
                      period,
                      events,
                      observedAt: observedAt[0],
                      recurringObservedAt: observedAt[1],
                    );
                  }
                  if (!cancelled &&
                      current == generation &&
                      currentOwnerId?.call() == ownerId) {
                    controller.add((
                      events: [
                        for (var index = 0; index < events.length; index++)
                          if (!allRecurringParents ||
                              period == null ||
                              events[index].recurrenceRule == null ||
                              _overlapsPeriod(entries[index].$1, period))
                            events[index],
                      ],
                      confirmed: complete,
                    ));
                  }
                } catch (error, stack) {
                  if (!cancelled && current == generation) {
                    controller.addError(error, stack);
                  }
                }
              },
              onError: (Object error, StackTrace stack) {
                generation++;
                received[bucket] = null;
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
