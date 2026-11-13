import 'package:memora/core/time/app_clock.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_events_usecase.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_watch_query_service.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_notification_source.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

class DeviceCalendarNotificationSource implements CalendarNotificationSource {
  DeviceCalendarNotificationSource({
    required this.currentMember,
    required this.groups,
    required this.events,
    required this.clock,
    this.database,
    this.firestore,
    this.watchEvents,
  });
  final WatchCalendarEventsUsecase? watchEvents;
  Future<List<CalendarEventDto>> Function()? _watchedLoad;
  final AppClock clock;
  final GetCurrentMemberUseCase currentMember;
  final GetGroupsWithMembersUsecase groups;
  final GetCalendarEventsUsecase events;
  final OfflineDatabase? database;
  final FirebaseFirestore? firestore;

  Future<List<String>> _groupIds() async {
    if (database != null) {
      return (await database!.rows('groups'))
          .map((v) => v['id'] as String)
          .toList();
    }
    final member = await currentMember.execute();
    if (member == null) return [];
    return (await groups.execute(member)).map((v) => v.id).toList();
  }

  @override
  Future<List<CalendarEventDto>> load() async {
    final watched = _watchedLoad;
    if (watched != null) return watched();
    final result = <CalendarEventDto>[];
    final period = CalendarEventPeriod.forNotifications(clock.now());
    for (final id in await _groupIds()) {
      result.addAll(await events.execute(id, period: period));
    }
    return result;
  }

  @override
  Stream<void> changes() {
    if (database != null) return database!.tableUpdates().map((_) {});
    final subscriptions = <StreamSubscription<dynamic>>[];
    final groupSubscriptions = <String, List<StreamSubscription<dynamic>>>{};
    final received = <String, List<CalendarEventDto>>{};
    final existing = <String>{};
    final loadedGroups = <String>{};
    var period = CalendarEventPeriod.forNotifications(clock.now());
    var closed = false;
    var revision = 0;
    var groupsReady = false;
    Object? failure;
    var ready = Completer<void>();
    late StreamController<void> controller;
    final watcher =
        watchEvents ??
        WatchCalendarEventsUsecase(
          FirestoreCalendarEventWatchQueryService(firestore: firestore!),
        );

    void error(Object e, StackTrace s) {
      if (closed) return;
      failure = e;
      if (!ready.isCompleted) ready.complete();
      controller.addError(e, s);
    }

    void publish() {
      if (closed ||
          !groupsReady ||
          groupSubscriptions.keys.any(
            (id) =>
                !loadedGroups.contains(id) ||
                (existing.contains(id) && !received.containsKey(id)),
          )) {
        return;
      }
      failure = null;
      if (!ready.isCompleted) ready.complete();
      controller.add(null);
    }

    void subscribe(String id) {
      final subscriptions = <StreamSubscription<dynamic>>[];
      groupSubscriptions[id] = subscriptions;
      subscriptions.add(
        firestore!.collection('groups').doc(id).snapshots().listen((doc) {
          if (closed || !identical(groupSubscriptions[id], subscriptions)) {
            return;
          }
          loadedGroups.add(id);
          if (doc.exists) {
            existing.add(id);
          } else {
            existing.remove(id);
            received.remove(id);
            groupSubscriptions.remove(id);
            loadedGroups.remove(id);
            for (final subscription in subscriptions) {
              unawaited(subscription.cancel());
            }
          }
          publish();
        }, onError: error),
      );
      subscriptions.add(
        watcher.execute(id, period: period).listen((events) {
          if (closed || !identical(groupSubscriptions[id], subscriptions)) {
            return;
          }
          received[id] = events;
          publish();
        }, onError: error),
      );
    }

    Future<void> updateGroups() async {
      final current = ++revision;
      try {
        final ids = await _groupIds();
        if (closed || current != revision) return;
        for (final id in groupSubscriptions.keys.toList()) {
          if (!ids.contains(id)) {
            final removed = groupSubscriptions.remove(id)!;
            received.remove(id);
            existing.remove(id);
            loadedGroups.remove(id);
            await Future.wait(removed.map((sub) => sub.cancel()));
            if (closed || current != revision) return;
          }
        }
        if (closed || current != revision) return;
        for (final id in ids) {
          if (!groupSubscriptions.containsKey(id)) subscribe(id);
        }
        groupsReady = true;
        publish();
      } catch (e, s) {
        error(e, s);
      }
    }

    Future<List<CalendarEventDto>> watchedLoad() async {
      final next = CalendarEventPeriod.forNotifications(clock.now());
      if (next.from != period.from) {
        final current = ++revision;
        period = next;
        if (!ready.isCompleted) ready.complete();
        ready = Completer<void>();
        final previous = groupSubscriptions.values.expand((v) => v).toList();
        groupSubscriptions.clear();
        received.clear();
        loadedGroups.clear();
        existing.clear();
        for (final sub in previous) {
          await sub.cancel();
        }
        if (!closed && current == revision) {
          await updateGroups();
        }
      }
      await ready.future;
      if (failure != null) throw failure!;
      if (closed) throw StateError('通知の監視は終了しています');
      return [for (final id in existing) ...?received[id]];
    }

    Future<void> start() async {
      try {
        final member = await currentMember.execute();
        if (closed || member == null) return;
        final uid = member.accountId;
        if (uid == null) return;
        subscriptions.add(
          firestore!
              .collection('account_permissions')
              .doc(uid)
              .snapshots()
              .listen((_) {
                unawaited(updateGroups());
              }, onError: error),
        );
      } catch (e, s) {
        error(e, s);
      }
    }

    controller = StreamController<void>(
      onListen: () {
        _watchedLoad = watchedLoad;
        unawaited(start());
      },
      onCancel: () async {
        closed = true;
        _watchedLoad = null;
        if (!ready.isCompleted) ready.complete();
        for (final sub in [
          ...subscriptions,
          ...groupSubscriptions.values.expand((v) => v),
        ]) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }
}
