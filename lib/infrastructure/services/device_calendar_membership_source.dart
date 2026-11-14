import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

class DeviceCalendarMembershipSource {
  const DeviceCalendarMembershipSource({this.firestore, this.database});
  final FirebaseFirestore? firestore;
  final OfflineDatabase? database;

  Stream<void> changes(String ownerId) {
    final local = database;
    if (local != null) {
      return local.tableUpdates().where((updates) => updates.any((update) => const {'groups', 'group_members', 'members'}.contains(update.table))).map((_) {});
    }
    late StreamController<void> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? permissions;
    final subscriptions = <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    var closed = false;
    void update(DocumentSnapshot<Map<String, dynamic>> doc) {
      if (closed) return;
      final ids = ((doc.data()?['memberGroupIds'] as List?) ?? []).cast<String>().toSet();
      for (final id in subscriptions.keys.toList()) {
        if (!ids.contains(id)) unawaited(subscriptions.remove(id)!.cancel());
      }
      for (final id in ids) {
        if (subscriptions.containsKey(id)) continue;
        subscriptions[id] = firestore!.collection('groups').doc(id).snapshots().listen((_) {
          if (!closed && subscriptions.containsKey(id)) controller.add(null);
        }, onError: controller.addError);
      }
      controller.add(null);
    }
    controller = StreamController<void>(onListen: () {
      permissions = firestore!.collection('account_permissions').doc(ownerId.substring('online:'.length)).snapshots().listen(update, onError: controller.addError);
    }, onCancel: () async {
      closed = true;
      await permissions?.cancel();
      for (final sub in subscriptions.values) { await sub.cancel(); }
    });
    return controller.stream;
  }
}
