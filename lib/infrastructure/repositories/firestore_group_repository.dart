import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/entities/group.dart';
import '../mappers/firestore_group_mapper.dart';
import '../mappers/firestore_group_member_mapper.dart';
import '../mappers/firestore_group_event_mapper.dart';

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveGroup(Group group) async {
    final docRef = await _firestore
        .collection('groups')
        .add(FirestoreGroupMapper.toFirestore(group));
    return docRef.id;
  }

  @override
  Future<void> updateGroup(Group group) async {
    await _firestore
        .collection('groups')
        .doc(group.id)
        .update(FirestoreGroupMapper.toFirestore(group));
  }

  @override
  Future<List<Group>> getGroups() async {
    try {
      final snapshot = await _firestore.collection('groups').get();
      final groups = snapshot.docs
          .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
          .toList();

      final List<Group> completeGroups = [];

      for (final group in groups) {
        final groupMembersSnapshot = await _firestore
            .collection('group_members')
            .where('groupId', isEqualTo: group.id)
            .get();

        final groupMembers = groupMembersSnapshot.docs
            .map((doc) => FirestoreGroupMemberMapper.fromFirestore(doc))
            .toList();

        final eventsSnapshot = await _firestore
            .collection('group_events')
            .where('groupId', isEqualTo: group.id)
            .get();

        final groupEvents = eventsSnapshot.docs
            .map((doc) => FirestoreGroupEventMapper.fromFirestore(doc))
            .toList();

        final completeGroup = group.copyWith(
          members: groupMembers,
          events: groupEvents,
        );

        completeGroups.add(completeGroup);
      }

      return completeGroups;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return FirestoreGroupMapper.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Group>> getGroupsByOwnerId(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Group>> getGroupsWhereUserIsAdmin(String memberId) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('ownerId', isEqualTo: memberId)
        .get();

    return snapshot.docs
        .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<Group>> getGroupsWhereUserIsMember(String memberId) async {
    final memberGroupsSnapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    final List<Group> groups = [];
    for (final doc in memberGroupsSnapshot.docs) {
      final groupId = doc.data()['groupId'] as String;
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists) {
        final group = FirestoreGroupMapper.fromFirestore(groupDoc);
        groups.add(group);
      }
    }
    return groups;
  }
}
