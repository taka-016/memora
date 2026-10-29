import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_notification_source.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

class DeviceCalendarNotificationSource implements CalendarNotificationSource {
  const DeviceCalendarNotificationSource({
    required this.currentMember,
    required this.groups,
    required this.events,
    this.database,
    this.firestore,
  });
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
    final result = <CalendarEventDto>[];
    for (final id in await _groupIds()) {
      result.addAll(await events.execute(id));
    }
    return result;
  }

  @override
  Stream<void> changes() {
    if (database != null) return database!.tableUpdates().map((_) {});
    final subscriptions = <StreamSubscription<dynamic>>[];
    final groupSubscriptions = <String, List<StreamSubscription<dynamic>>>{};
    var closed = false;
    var revision = 0;
    late StreamController<void> controller;
    void error(Object e, StackTrace s) {
      if (!closed) controller.addError(e, s);
    }

    Future<void> updateGroups() async {
      final current = ++revision;
      try {
        final ids = await _groupIds();
        if (closed || current != revision) return;
        for (final id in groupSubscriptions.keys.toList()) {
          if (!ids.contains(id)) {
            for (final sub in groupSubscriptions.remove(id)!) {
              await sub.cancel();
            }
          }
        }
        for (final id in ids) {
          if (closed) return;
          if (groupSubscriptions.containsKey(id)) continue;
          groupSubscriptions[id] = [
            firestore!.collection('groups').doc(id).snapshots().listen((_) {
              if (!closed) controller.add(null);
            }, onError: error),
            firestore!
                .collection('calendar_events')
                .where('groupId', isEqualTo: id)
                .snapshots()
                .listen((_) {
                  if (!closed) controller.add(null);
                }, onError: error),
          ];
        }
        if (!closed) controller.add(null);
      } catch (e, s) {
        error(e, s);
      }
    }

    Future<void> start() async {
      try {
        final member = await currentMember.execute();
        if (closed || member == null) return;
        subscriptions.addAll([
          firestore!
              .collection('group_members')
              .where('memberId', isEqualTo: member.id)
              .snapshots()
              .listen((_) {
                unawaited(updateGroups());
              }, onError: error),
          firestore!
              .collection('groups')
              .where('ownerId', isEqualTo: member.id)
              .snapshots()
              .listen((_) {
                unawaited(updateGroups());
              }, onError: error),
        ]);
      } catch (e, s) {
        error(e, s);
      }
    }

    controller = StreamController<void>(
      onListen: () {
        unawaited(start());
      },
      onCancel: () async {
        closed = true;
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
