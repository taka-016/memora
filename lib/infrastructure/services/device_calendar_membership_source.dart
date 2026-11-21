import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

class DeviceCalendarMembershipSource {
  const DeviceCalendarMembershipSource({this.firestore, this.database});
  final FirebaseFirestore? firestore;
  final OfflineDatabase? database;

  Stream<void> changes(String memberId) {
    final local = database;
    if (local != null) {
      return local
          .tableUpdates()
          .where(
            (updates) => updates.any(
              (update) => const {
                'groups',
                'group_members',
                'members',
              }.contains(update.table),
            ),
          )
          .map((_) {});
    }
    late StreamController<void> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? memberships;
    final subscriptions =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    var closed = false;
    void update(QuerySnapshot<Map<String, dynamic>> snapshot) {
      if (closed) return;
      final ids = snapshot.docs
          .map((doc) => doc.data()['groupId'] as String)
          .toSet();
      for (final id in subscriptions.keys.toList()) {
        if (!ids.contains(id)) unawaited(subscriptions.remove(id)!.cancel());
      }
      for (final id in ids) {
        if (subscriptions.containsKey(id)) continue;
        subscriptions[id] = firestore!
            .collection('groups')
            .doc(id)
            .snapshots()
            .listen((_) {
              if (!closed && subscriptions.containsKey(id)) {
                controller.add(null);
              }
            }, onError: controller.addError);
      }
      controller.add(null);
    }

    controller = StreamController<void>(
      onListen: () {
        memberships = firestore!
            .collection('group_members')
            .where('memberId', isEqualTo: memberId)
            .snapshots()
            .listen(update, onError: controller.addError);
      },
      onCancel: () async {
        closed = true;
        await memberships?.cancel();
        for (final sub in subscriptions.values) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }
}
