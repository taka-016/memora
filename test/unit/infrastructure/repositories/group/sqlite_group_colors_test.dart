import 'package:memora/application/queries/order_by.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/queries/group/sqlite_group_query_service.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';

void main() {
  test('所属の追加・色変更・並べ替えを保存し同一メンバーの別グループ色は保持する', () async {
    final db = OfflineDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SqliteGroupRepository(db);
    final query = SqliteGroupQueryService(db);
    for (final id in ['a', 'b', 'c']) { await db.insertRow('members', {'id': id, 'display_name': id}); }
    final firstId = await repo.saveGroup(Group(id: '', ownerId: 'a', name: '家族', color: '#FF0000', members: const [GroupMember(groupId: '', memberId: 'a', color: '#123456')]));
    final secondId = await repo.saveGroup(Group(id: '', ownerId: 'a', name: '友人', members: const [GroupMember(groupId: '', memberId: 'a', color: '#ABCDEF')]));
    final original = (await query.getGroupWithMembersById(firstId))!;
    await repo.updateGroup(GroupMapper.toEntity(original.copyWith(members: [original.members.single.copyWith(color: '#654321', orderIndex: 2)])));
    final colored = (await query.getGroupWithMembersById(firstId))!;
    expect(colored.members.single.color, '#654321');
    final withNew = GroupMapper.toEntity(colored).copyWith(members: [
      ...GroupMapper.toEntity(colored).members,
      GroupMember(groupId: firstId, memberId: 'b', color: '#FFFF00', orderIndex: 0),
    ]);
    await repo.updateGroup(withNew);
    final saved = (await query.getGroupWithMembersById(firstId, membersOrderBy: const [OrderBy('orderIndex')]))!;
    expect(saved.members.map((v) => (v.memberId, v.color, v.orderIndex)), [('b', '#FFFF00', 0), ('a', '#654321', 2)]);
    expect((await query.getGroupWithMembersById(secondId))!.members.single.color, '#ABCDEF');
    expect(saved.color, '#FF0000');
  });
}
