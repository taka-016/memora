import 'package:memora/infrastructure/services/firestore_version_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_event_mapper.dart';

class FirestoreGroupEventRepository implements GroupEventRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveGroupEvent(GroupEvent groupEvent) async {
    if (groupEvent.id.isEmpty) {
      final data = FirestoreGroupEventMapper.toCreateFirestore(groupEvent);
      final docRef = await _firestore.collection('group_events').add(data);
      return docRef.id;
    }

    final data = FirestoreGroupEventMapper.toUpdateFirestore(groupEvent);
    await _firestore.collection('group_events').doc(groupEvent.id).update(data);
    return groupEvent.id;
  }

  @override
  Future<void> deleteGroupEvent(
    String groupEventId, {
    int? expectedVersion,
  }) async {
    await FirestoreVersionCheck.delete(_firestore, _firestore.collection('group_events').doc(groupEventId), expectedVersion);
  }

  @override
  Future<void> deleteGroupEventsByGroupId(String groupId) async {
    final snapshot = await _firestore
        .collection('group_events')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
