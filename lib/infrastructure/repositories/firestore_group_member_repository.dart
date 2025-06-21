import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../domain/entities/group_member.dart';
import '../mappers/firestore_group_member_mapper.dart';

class FirestoreGroupMemberRepository implements GroupMemberRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupMemberRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveGroupMember(GroupMember groupMember) async {
    await _firestore
        .collection('group_members')
        .add(FirestoreGroupMemberMapper.toFirestore(groupMember));
  }

  @override
  Future<List<GroupMember>> getGroupMembers() async {
    try {
      final snapshot = await _firestore.collection('group_members').get();
      return snapshot.docs
          .map((doc) => FirestoreGroupMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteGroupMember(String groupMemberId) async {
    await _firestore.collection('group_members').doc(groupMemberId).delete();
  }

  @override
  Future<List<GroupMember>> getGroupMembersByGroupId(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreGroupMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
