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
      final adminGroupsSnapshot = await _firestore
          .collection('groups')
          .where('administratorId', isEqualTo: memberId)
          .get();

      final memberGroupsSnapshot = await _firestore
          .collection('group_members')
          .where('memberId', isEqualTo: memberId)
          .get();

      final Set<String> groupIds = {};
      final List<Group> allGroups = [];

      for (final doc in adminGroupsSnapshot.docs) {
        final group = FirestoreGroupMapper.fromFirestore(doc);
        if (!groupIds.contains(group.id)) {
          groupIds.add(group.id);
          allGroups.add(group);
        }
      }

      for (final doc in memberGroupsSnapshot.docs) {
        final groupId = doc.data()['groupId'] as String;
        if (!groupIds.contains(groupId)) {
          final groupDoc = await _firestore
              .collection('groups')
              .doc(groupId)
              .get();
          if (groupDoc.exists) {
            final group = FirestoreGroupMapper.fromFirestore(groupDoc);
            groupIds.add(group.id);
            allGroups.add(group);
          }
        }
      }

      final List<GroupWithMembers> result = [];
      for (final group in allGroups) {
        final groupMembersSnapshot = await _firestore
            .collection('group_members')
            .where('groupId', isEqualTo: group.id)
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

        result.add(GroupWithMembers(group: group, members: members));
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}
