import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';
import 'package:memora/infrastructure/services/firestore_account_permissions_source.dart';
import 'package:memora/infrastructure/services/firestore_version_check.dart';

class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository({
    FirebaseFirestore? firestore,
    FirestoreAccountPermissionsSource? permissions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _permissions =
           permissions ??
           FirestoreAccountPermissionsSource(
             firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final FirestoreAccountPermissionsSource _permissions;

  @override
  Future<String> saveGroup(Group group) async {
    final self = await _permissions.current();
    if (self == null) throw StateError('本人の登録が必要です');
    final ref = _firestore.collection('groups').doc();
    final members = {for (final m in group.members) m.memberId: m};
    members.putIfAbsent(
      self.memberId,
      () => GroupMember(groupId: ref.id, memberId: self.memberId),
    );
    final created = group.copyWith(
      id: ref.id,
      ownerId: self.memberId,
      members: members.values.toList(),
    );
    await _firestore.runTransaction<void>((tx) async {
      final profiles = await _readMembers(tx, members.keys);
      tx.set(ref, FirestoreGroupMapper.toCreateFirestore(created));
      for (final member in members.values) {
        tx.set(
          _membership(ref.id, member.memberId),
          FirestoreGroupMemberMapper.toCreateFirestore(
            member.copyWith(groupId: ref.id),
          ),
        );
        _saveMembership(
          tx,
          member.memberId,
          profiles[member.memberId]!,
          ref.id,
          included: true,
          managed: member.isAdministrator || member.memberId == self.memberId,
        );
      }
    });
    return ref.id;
  }

  @override
  Future<void> updateGroup(Group group) async {
    final before = {for (final m in group.originalMembers) m.memberId: m};
    final after = {for (final m in group.members) m.memberId: m};
    if (before.containsKey(group.ownerId) && !after.containsKey(group.ownerId)) throw StateError('所有者の所属は解除できません');
    final ids = {...before.keys, ...after.keys};
    await _firestore.runTransaction<void>((tx) async {
      final ref = _firestore.collection('groups').doc(group.id);
      FirestoreVersionCheck.requireMatch(
        (await tx.get(ref)).data(),
        group.version,
      );
      final changed = ids.where((id) => before[id] != after[id]).toList();
      final profiles = await _readMembers(
        tx,
        changed.where(
          (id) =>
              before[id] == null ||
              after[id] == null ||
              before[id]!.isAdministrator != after[id]!.isAdministrator,
        ),
      );
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
        final data = profiles[id];
        if (data == null) continue;
        _saveMembership(
          tx,
          id,
          data,
          group.id,
          included: member != null,
          managed:
              member != null && (member.isAdministrator || id == group.ownerId),
        );
      }
    });
  }

  @override
  Future<void> deleteGroup(String groupId, {int? expectedVersion}) async {
    final source = _firestore.collection('groups').doc(groupId);
    final links = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get(const GetOptions(source: Source.server));
    final ids = links.docs
        .map((doc) => doc.data()['memberId'] as String)
        .toSet();
    await _firestore.runTransaction<void>((tx) async {
      final data = (await tx.get(source)).data();
      FirestoreVersionCheck.requireMatch(data, expectedVersion);
      final profiles = await _readMembers(tx, ids);
      tx.set(_firestore.collection('deleted_groups').doc(groupId), data!);
      tx.delete(source);
      for (final entry in profiles.entries) {
        if (entry.value == null) continue;
        _saveMembership(
          tx,
          entry.key,
          entry.value!,
          groupId,
          included: false,
          managed: false,
        );
      }
    });
  }

  DocumentReference<Map<String, dynamic>> _membership(
    String groupId,
    String memberId,
  ) => _firestore.collection('group_members').doc('$groupId:$memberId');

  Future<Map<String, Map<String, dynamic>?>> _readMembers(
    Transaction tx,
    Iterable<String> ids,
  ) async {
    final result = <String, Map<String, dynamic>?>{};
    for (final id in ids) {
      result[id] = (await tx.get(_firestore.collection('members').doc(id)))
          .data();
    }
    return result;
  }

  void _saveMembership(
    Transaction tx,
    String memberId,
    Map<String, dynamic> data,
    String groupId, {
    required bool included,
    required bool managed,
  }) {
    final groups = List<String>.from(data['groupIds'] as List);
    final managers = List<String>.from(data['managedGroupIds'] as List);
    if (groups.contains(groupId) == included &&
        managers.contains(groupId) == managed) {
      return;
    }
    groups.remove(groupId);
    managers.remove(groupId);
    if (included) groups.add(groupId);
    if (managed) managers.add(groupId);
    final version = data['version'] as int?;
    FirestoreVersionCheck.requireMatch(data, version);
    tx.update(_firestore.collection('members').doc(memberId), {
      'groupIds': groups,
      'managedGroupIds': managers,
      'changedGroupId': groupId,
      'version': version! + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final accountId = data['accountId'] as String?;
    if (accountId != null) {
      tx.update(_firestore.collection('account_permissions').doc(accountId), {
        'memberGroupIds': groups,
        'managedGroupIds': managers,
        'changedGroupId': groupId,
      });
    }
  }

  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async {
    throw UnsupportedError('所属はグループの更新で解除してください');
  }
}
