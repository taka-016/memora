import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';
import 'package:memora/infrastructure/services/firestore_account_member_source.dart';
import 'package:memora/infrastructure/services/firestore_version_check.dart';

class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository({
    FirebaseFirestore? firestore,
    FirestoreAccountMemberSource? accountMember,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _accountMember =
           accountMember ??
           FirestoreAccountMemberSource(
             firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final FirestoreAccountMemberSource _accountMember;

  @override
  Future<String> saveGroup(Group group) async {
    final self = await _accountMember.current();
    if (self == null) throw StateError('本人の登録が必要です');
    final ref = _firestore.collection('groups').doc();
    final members = {for (final m in group.members) m.memberId: m};
    members.putIfAbsent(
      self.id,
      () => GroupMember(groupId: ref.id, memberId: self.id),
    );
    final created = group.copyWith(
      id: ref.id,
      ownerId: self.id,
      members: members.values.toList(),
    );
    await _firestore.runTransaction<void>((tx) async {
      tx.set(ref, FirestoreGroupMapper.toCreateFirestore(created));
      for (final member in members.values) {
        tx.set(
          _membership(ref.id, member.memberId),
          FirestoreGroupMemberMapper.toCreateFirestore(
            member.copyWith(groupId: ref.id),
          ),
        );
      }
    });
    return ref.id;
  }

  @override
  Future<void> updateGroup(Group group) async {
    final before = {for (final m in group.originalMembers) m.memberId: m};
    final after = {for (final m in group.members) m.memberId: m};
    if (before.containsKey(group.ownerId) &&
        !after.containsKey(group.ownerId)) {
      throw StateError('所有者の所属は解除できません');
    }
    final ids = {...before.keys, ...after.keys};
    await _firestore.runTransaction<void>((tx) async {
      final ref = _firestore.collection('groups').doc(group.id);
      FirestoreVersionCheck.requireMatch(
        (await tx.get(ref)).data(),
        group.version,
      );
      final changed = ids.where((id) => before[id] != after[id]).toList();
      tx.update(ref, FirestoreGroupMapper.toUpdateFirestore(group));
      for (final id in changed) {
        final member = after[id];
        if (member == null) {
          tx.delete(_membership(group.id, id));
        } else {
          tx.set(
            _membership(group.id, id),
            FirestoreGroupMemberMapper.toCreateFirestore(member),
          );
        }
      }
    });
  }

  @override
  Future<void> deleteGroup(String groupId, {int? expectedVersion}) async {
    final source = _firestore.collection('groups').doc(groupId);
    await _firestore.runTransaction<void>((tx) async {
      final data = (await tx.get(source)).data();
      FirestoreVersionCheck.requireMatch(data, expectedVersion);
      tx.set(_firestore.collection('deleted_groups').doc(groupId), data!);
      tx.delete(source);
    });
  }

  DocumentReference<Map<String, dynamic>> _membership(
    String groupId,
    String memberId,
  ) => _firestore.collection('group_members').doc('$groupId:$memberId');

  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async {
    throw UnsupportedError('所属はグループの更新で解除してください');
  }
}
