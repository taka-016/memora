import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_member_mapper.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_mapper.dart';

class SqliteGroupQueryService implements GroupQueryService {
  SqliteGroupQueryService(this.db);
  final OfflineDatabase db;
  Future<GroupDto> _group(Map<String, Object?> row, List<OrderBy>? orderBy) async {
    final links = await db.rows('group_members', where: 'group_id = ?', args: [row['id']!], orderBy: orderBy);
    final members = <GroupMemberDto>[];
    for (final link in links) {
      final member = (await db.rows('members', where: 'id = ?', args: [link['member_id']!])).single;
      members.add(SqliteGroupMemberMapper.fromRow(link, SqliteMemberMapper.fromRow(member)));
    }
    return SqliteGroupMapper.fromRow(row, members: members);
  }
  @override
  Future<GroupDto?> getGroupWithMembersById(String groupId, {List<OrderBy>? membersOrderBy}) async => db.transaction(() async {
    final rows = await db.rows('groups', where: 'id = ?', args: [groupId]);
    return rows.isEmpty ? null : await _group(rows.single, membersOrderBy);
  });
  @override
  Future<List<GroupDto>> getManagedGroupsWithMembersByOwnerId(String ownerId, {List<OrderBy>? groupsOrderBy, List<OrderBy>? membersOrderBy}) async => _groups('owner_id = ?', [ownerId], groupsOrderBy, membersOrderBy);
  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(String memberId, {List<OrderBy>? groupsOrderBy, List<OrderBy>? membersOrderBy}) async => _groups('owner_id = ? OR id IN (SELECT group_id FROM group_members WHERE member_id = ?)', [memberId, memberId], groupsOrderBy, membersOrderBy);
  Future<List<GroupDto>> _groups(String where, List<Object> args, List<OrderBy>? groupsOrderBy, List<OrderBy>? membersOrderBy) async => db.transaction(() async {
    final rows = await db.rows('groups', where: where, args: args, orderBy: groupsOrderBy);
    final result = <GroupDto>[];
    for (final row in rows) { result.add(await _group(row, membersOrderBy)); }
    return result;
  });
}
