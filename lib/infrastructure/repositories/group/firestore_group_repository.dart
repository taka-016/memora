import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveGroup(Group group) async {
    final batch = _firestore.batch();

    final groupDocRef = _firestore.collection('groups').doc();
    batch.set(groupDocRef, FirestoreGroupMapper.toCreateFirestore(group));

    for (final GroupMember member in group.members) {
      final memberDocRef = _firestore.collection('group_members').doc();
      batch.set(
        memberDocRef,
        FirestoreGroupMemberMapper.toCreateFirestore(
          member.copyWith(groupId: groupDocRef.id),
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
      FirestoreGroupMapper.toUpdateFirestore(group),
    );

    final memberSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: group.id)
        .get();
    final existing = {for (final doc in memberSnapshot.docs) doc.data()['memberId'] as String: doc.reference};
    final before = {for (final member in group.originalMembers) member.memberId: member};
    final after = {for (final member in group.members) member.memberId: member};
    for (final id in before.keys.where((id) => !after.containsKey(id))) {
      final reference = existing[id];
      if (reference != null) batch.delete(reference);
    }
    for (final member in group.members) {
      if (before[member.memberId] == member) continue;
      final reference = existing[member.memberId];
      if (reference == null) {
        batch.set(_firestore.collection('group_members').doc(), FirestoreGroupMemberMapper.toCreateFirestore(member.copyWith(groupId: group.id)));
      } else {
        batch.update(reference, {'isAdministrator': member.isAdministrator, 'orderIndex': member.orderIndex});
      }
    }

    await batch.commit();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final source = _firestore.collection('groups').doc(groupId);
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(source);
      final data = snapshot.data();
      if (data == null) return;
      transaction.set(
        _firestore.collection('deleted_groups').doc(groupId),
        data,
      );
      transaction.delete(source);
    });
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
}
