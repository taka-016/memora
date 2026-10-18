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
    await db.insertRow(
      'groups',
      SqliteGroupMapper.toRow(group.copyWith(id: id)),
    );
    await _members(group.copyWith(id: id));
    return id;
  });
  @override
  Future<void> updateGroup(Group group) async => db.transaction(() async {
    await db.updateRow('groups', group.id, SqliteGroupMapper.toRow(group));
    final before = {
      for (final member in group.originalMembers) member.memberId: member,
    };
    final after = {for (final member in group.members) member.memberId: member};
    for (final id in before.keys.where((id) => !after.containsKey(id))) {
      await db.customStatement(
        'DELETE FROM group_members WHERE group_id = ? AND member_id = ?',
        [group.id, id],
      );
    }
    for (final member in group.members) {
      final previous = before[member.memberId];
      if (previous == member) continue;
      final row = SqliteGroupMemberMapper.toRow(
        member.copyWith(groupId: group.id),
      );
      if (previous == null) {
        await db.customStatement(
          'INSERT INTO group_members (group_id, member_id, is_administrator, order_index) VALUES (?, ?, ?, ?) ON CONFLICT(group_id, member_id) DO NOTHING',
          row.values.toList(),
        );
      } else {
        await db.customStatement(
          'UPDATE group_members SET is_administrator = ?, order_index = ? WHERE group_id = ? AND member_id = ?',
          [
            member.isAdministrator ? 1 : 0,
            member.orderIndex,
            group.id,
            member.memberId,
          ],
        );
      }
    }
  });
  Future<void> _members(Group group) async {
    for (final member in group.members) {
      await db.insertRow(
        'group_members',
        SqliteGroupMemberMapper.toRow(member.copyWith(groupId: group.id)),
      );
    }
  }

  @override
  Future<void> deleteGroup(String groupId, {int? expectedVersion}) async =>
      db.transaction(() async {
        final rows = await db.rows('groups', where: 'id = ?', args: [groupId]);
        if (rows.isEmpty) return;
        await db.insertRow('deleted_groups', rows.single);
        await db.deleteRows('groups', 'id', groupId);
      });
  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async =>
      db.deleteRows('group_members', 'member_id', memberId);
}
