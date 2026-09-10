import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_member_mapper.dart';

class SqliteGroupRepository implements GroupRepository {
  SqliteGroupRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<String> saveGroup(Group group) async => db.transaction(() async {
    final id = const Uuid().v4();
    await db.insertRow('groups', SqliteGroupMapper.toRow(group.copyWith(id: id)));
    await _members(group.copyWith(id: id));
    return id;
  });
  @override
  Future<void> updateGroup(Group group) async => db.transaction(() async {
    await db.updateRow('groups', group.id, SqliteGroupMapper.toRow(group));
    await db.deleteRows('group_members', 'group_id', group.id);
    await _members(group);
  });
  Future<void> _members(Group group) async {
    for (final member in group.members) {
      await db.insertRow('group_members', SqliteGroupMemberMapper.toRow(member.copyWith(groupId: group.id)));
    }
  }
  @override
  Future<void> deleteGroup(String groupId) async => db.deleteRows('groups', 'id', groupId);
  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async => db.deleteRows('group_members', 'member_id', memberId);
}
