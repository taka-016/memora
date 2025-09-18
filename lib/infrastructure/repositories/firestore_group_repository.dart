import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group_event.dart';
import 'package:memora/domain/entities/group_member.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/entities/group.dart';
import '../mappers/firestore_group_mapper.dart';
import '../mappers/firestore_group_member_mapper.dart';
import '../mappers/firestore_group_event_mapper.dart';
import '../../core/app_logger.dart';

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveGroup(Group group) async {
    final batch = _firestore.batch();

    final groupDocRef = _firestore.collection('groups').doc();
    batch.set(groupDocRef, FirestoreGroupMapper.toFirestore(group));

    for (final GroupMember member in group.members ?? []) {
      final memberDocRef = _firestore.collection('group_members').doc();
      batch.set(
        memberDocRef,
        FirestoreGroupMemberMapper.toFirestore(
          member.copyWith(groupId: groupDocRef.id),
        ),
      );
    }

    for (final GroupEvent event in group.events ?? []) {
      final eventDocRef = _firestore.collection('group_events').doc();
      batch.set(
        eventDocRef,
        FirestoreGroupEventMapper.toFirestore(
          event.copyWith(groupId: groupDocRef.id),
        ),
      );
    }

    await batch.commit();
    return groupDocRef.id;
  }

  @override
  Future<void> updateGroup(Group group) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('groups').doc(group.id),
      FirestoreGroupMapper.toFirestore(group),
    );

    if (group.members != null) {
      final memberSnapshot = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: group.id)
          .get();
      for (final doc in memberSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final GroupMember member in group.members!) {
        final memberDocRef = _firestore.collection('group_members').doc();
        batch.set(
          memberDocRef,
          FirestoreGroupMemberMapper.toFirestore(
            member.copyWith(groupId: group.id),
          ),
        );
      }
    }

    if (group.events != null) {
      final eventSnapshot = await _firestore
          .collection('group_events')
          .where('groupId', isEqualTo: group.id)
          .get();
      for (final doc in eventSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final GroupEvent event in group.events!) {
        final eventDocRef = _firestore.collection('group_events').doc();
        batch.set(
          eventDocRef,
          FirestoreGroupEventMapper.toFirestore(
            event.copyWith(groupId: group.id),
          ),
        );
      }
    }

    await batch.commit();
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
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupRepository.getGroups: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final batch = _firestore.batch();

    final memberSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in memberSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final eventSnapshot = await _firestore
        .collection('group_events')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in eventSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('groups').doc(groupId));
    await batch.commit();
  }

  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return FirestoreGroupMapper.fromFirestore(doc);
      }
      return null;
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupRepository.getGroupById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupRepository.getGroupsByOwnerId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
