import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/calendar/calendar_group_watch_query_service.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';

class FirestoreCalendarGroupWatchQueryService
    implements CalendarGroupWatchQueryService {
  FirestoreCalendarGroupWatchQueryService(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Stream<GroupDto?> watchCalendarGroup(String groupId) {
    late StreamController<GroupDto?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? parent;
    final members =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    var generation = 0;
    var active = true;

    Future<void> refresh() async {
      final version = ++generation;
      try {
        final group = await FirestoreGroupQueryService(firestore: firestore)
            .getGroupWithMembersById(groupId);
        if (!active || version != generation) return;
        final ids =
            group?.members.map((member) => member.memberId).toSet() ??
            <String>{};
        for (final id in members.keys.toList()) {
          if (!ids.contains(id)) await members.remove(id)!.cancel();
        }
        if (!active || version != generation) return;
        for (final id in ids) {
          if (members.containsKey(id)) continue;
          members[id] = firestore
              .collection('members')
              .doc(id)
              .snapshots()
              .listen(
                (_) => unawaited(refresh()),
                onError: controller.addError,
              );
        }
        controller.add(group);
      } catch (error, stack) {
        if (active && version == generation) controller.addError(error, stack);
      }
    }

    controller = StreamController<GroupDto?>(
      onListen: () {
        parent = firestore
            .collection('groups')
            .doc(groupId)
            .snapshots()
            .listen((_) => unawaited(refresh()), onError: controller.addError);
      },
      onCancel: () async {
        active = false;
        generation++;
        await parent?.cancel();
        await Future.wait(
          members.values.map((subscription) => subscription.cancel()),
        );
        members.clear();
      },
    );
    return controller.stream;
  }
}
