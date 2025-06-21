import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../../domain/entities/group_event.dart';
import '../mappers/firestore_group_event_mapper.dart';

class FirestoreGroupEventRepository implements GroupEventRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveGroupEvent(GroupEvent groupEvent) async {
    await _firestore
        .collection('group_events')
        .add(FirestoreGroupEventMapper.toFirestore(groupEvent));
  }

  @override
  Future<List<GroupEvent>> getGroupEvents() async {
    try {
      final snapshot = await _firestore.collection('group_events').get();
      return snapshot.docs
          .map((doc) => FirestoreGroupEventMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteGroupEvent(String groupEventId) async {
    await _firestore.collection('group_events').doc(groupEventId).delete();
  }

  @override
  Future<List<GroupEvent>> getGroupEventsByGroupId(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('group_events')
          .where('groupId', isEqualTo: groupId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreGroupEventMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
