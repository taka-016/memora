import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/calendar/calendar_group_watch_query_service.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';

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

    DocumentSnapshot<Map<String, dynamic>>? group;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? links;
    final receivedMembers = <String, DocumentSnapshot<Map<String, dynamic>>>{};

    void publish() {
      final currentGroup = group;
      final currentLinks = links;
      if (!active || currentGroup == null || currentLinks == null) return;
      if (currentLinks.any(
        (link) => !receivedMembers.containsKey(link.data()['memberId']),
      )) {
        return;
      }
      controller.add(
        FirestoreGroupMapper.fromFirestore(
          currentGroup,
          members: [
            for (final link in currentLinks)
              if (receivedMembers[link.data()['memberId']]!.exists)
                FirestoreGroupMemberMapper.fromFirestore(
                  link,
                  receivedMembers[link.data()['memberId']]!,
                ),
          ],
        ),
      );
    }

    Future<void> refresh(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) async {
      final version = ++generation;
      group = snapshot;
      links = null;
      try {
        final fetched = snapshot.exists
            ? (await firestore
                      .collection('group_members')
                      .where('groupId', isEqualTo: groupId)
                      .get())
                  .docs
            : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (!active || version != generation) return;
        final ids = fetched
            .map((link) => link.data()['memberId'] as String)
            .toSet();
        for (final id in members.keys.toList()) {
          if (!ids.contains(id)) {
            receivedMembers.remove(id);
            await members.remove(id)!.cancel();
          }
        }
        if (!active || version != generation) return;
        links = fetched;
        for (final id in ids) {
          if (members.containsKey(id)) continue;
          members[id] = firestore
              .collection('members')
              .doc(id)
              .snapshots()
              .listen((member) {
                if (!active || !members.containsKey(id)) return;
                receivedMembers[id] = member;
                publish();
              }, onError: controller.addError);
        }
        if (!snapshot.exists) {
          controller.add(null);
        } else {
          publish();
        }
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
            .listen(
              (snapshot) => unawaited(refresh(snapshot)),
              onError: controller.addError,
            );
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
