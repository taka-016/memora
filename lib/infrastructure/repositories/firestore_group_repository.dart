import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_with_members.dart';
import '../../domain/entities/member.dart';
import '../mappers/firestore_group_mapper.dart';
import '../mappers/firestore_member_mapper.dart';

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
      return snapshot.docs
          .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
          .toList();
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
  Future<List<Group>> getGroupsByAdministratorId(String administratorId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('administratorId', isEqualTo: administratorId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<GroupWithMembers>> getGroupsWithMembersByMemberId(
    String memberId,
  ) async {
    try {
      final adminGroups = await _getGroupsWhereUserIsAdmin(memberId);
      final memberGroups = await _getGroupsWhereUserIsMember(memberId);
      final allGroups = _mergeUniqueGroups(adminGroups, memberGroups);

      return await _addMembersToGroups(allGroups);
    } catch (e) {
      return [];
    }
  }

  Future<List<Group>> _getGroupsWhereUserIsAdmin(String memberId) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('administratorId', isEqualTo: memberId)
        .get();

    return snapshot.docs
        .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
        .toList();
  }

  Future<List<Group>> _getGroupsWhereUserIsMember(String memberId) async {
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

  List<Group> _mergeUniqueGroups(
    List<Group> adminGroups,
    List<Group> memberGroups,
  ) {
    final Set<String> groupIds = {};
    final List<Group> uniqueGroups = [];

    for (final group in adminGroups) {
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        uniqueGroups.add(group);
      }
    }

    for (final group in memberGroups) {
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        uniqueGroups.add(group);
      }
    }

    return uniqueGroups;
  }

  Future<List<GroupWithMembers>> _addMembersToGroups(List<Group> groups) async {
    final List<GroupWithMembers> result = [];

    for (final group in groups) {
      final members = await _getMembersForGroup(group.id);
      result.add(GroupWithMembers(group: group, members: members));
    }

    return result;
  }

  Future<List<Member>> _getMembersForGroup(String groupId) async {
    final groupMembersSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get();

    final List<Member> members = [];
    for (final doc in groupMembersSnapshot.docs) {
      final memberId = doc.data()['memberId'] as String;
      final memberDoc = await _firestore
          .collection('members')
          .doc(memberId)
          .get();
      if (memberDoc.exists) {
        final member = FirestoreMemberMapper.fromFirestore(memberDoc);
        members.add(member);
      }
    }
    return members;
  }

  @override
  Future<List<GroupWithMembers>> getManagedGroupsWithMembersByAdministratorId(
    String administratorId,
  ) async {
    try {
      final managedGroups = await getGroupsByAdministratorId(administratorId);
      return await _addMembersToGroups(managedGroups);
    } catch (e) {
      return [];
    }
  }
}
