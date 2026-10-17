import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/queries/group/sqlite_group_query_service.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';
import 'package:memora/infrastructure/repositories/member/sqlite_member_repository.dart';

void main() {
  late OfflineDatabase db;
  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    await db.insertRow('groups', {'id': 'g', 'owner_id': 'a', 'name': '家族'});
    for (final id in ['a', 'b', 'c', 'd']) {
      await db.insertRow('members', {'id': id, 'display_name': id});
    }
    for (final id in ['a', 'b', 'c']) {
      await db.insertRow('group_members', {
        'group_id': 'g',
        'member_id': id,
        'is_administrator': id == 'b' ? 1 : 0,
        'order_index': id.codeUnitAt(0),
      });
    }
  });
  tearDown(() => db.close());

  test('退避済み所属を表示せず名前だけの更新と通常所属の差分更新でも保持する', () async {
    await SqliteMemberRepository(db).deleteMember('b');
    final query = SqliteGroupQueryService(db);
    final repo = SqliteGroupRepository(db);
    final hidden = (await db.rows(
      'group_members',
      where: 'member_id = ?',
      args: ['b'],
    )).single;
    var group = (await query.getGroupWithMembersById('g'))!;
    expect(group.members.map((m) => m.memberId), ['a', 'c']);
    await repo.updateGroup(GroupMapper.toEntity(group.copyWith(name: '変更')));
    group = (await query.getGroupWithMembersById('g'))!;
    final edited = group.copyWith(
      members: [
        group.members.first.copyWith(isAdministrator: true, orderIndex: 0),
        const GroupMemberDto(
          groupId: 'g',
          memberId: 'd',
          displayName: 'd',
          isAdministrator: false,
          orderIndex: 1,
        ),
      ],
    );
    await repo.updateGroup(GroupMapper.toEntity(edited));
    await repo.updateGroup(GroupMapper.toEntity(edited));
    expect(
      (await db.rows(
        'group_members',
        where: 'member_id = ?',
        args: ['b'],
      )).single,
      hidden,
    );
    final result = (await query.getGroupWithMembersById('g'))!;
    expect(result.members.map((m) => m.memberId), ['a', 'd']);
    expect(result.members.first.isAdministrator, isTrue);
    expect(result.members.map((m) => m.orderIndex), [0, 1]);
    expect(await db.rows('group_members'), hasLength(3));
  });

  for (final table in ['groups', 'members']) {
    test('$tableの退避保存が失敗しても元データを失わない', () async {
      final id = table == 'groups' ? 'g' : 'b';
      final before = await db.rows(table);
      await db.customStatement(
        'CREATE TRIGGER reject_archive BEFORE INSERT ON deleted_$table BEGIN SELECT RAISE(ABORT, \'退避失敗\'); END',
      );
      await expectLater(
        table == 'groups'
            ? SqliteGroupRepository(db).deleteGroup(id)
            : SqliteMemberRepository(db).deleteMember(id),
        throwsA(isA<Exception>()),
      );
      expect(await db.rows(table), before);
      expect(await db.rows('deleted_$table'), isEmpty);
    });
  }

  test('所属の更新失敗時はグループ名とすべての所属を元に戻す', () async {
    final group = (await SqliteGroupQueryService(db)
        .getGroupWithMembersById('g'))!;
    final before = await db.rows('group_members');
    await db.customStatement(
      "CREATE TRIGGER reject_link BEFORE UPDATE ON group_members BEGIN SELECT RAISE(ABORT, '所属更新失敗'); END",
    );
    await expectLater(
      SqliteGroupRepository(db).updateGroup(
        GroupMapper.toEntity(
          group.copyWith(
            name: '変更',
            members: [group.members.first.copyWith(isAdministrator: true)],
          ),
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(await db.rows('group_members'), before);
    expect((await db.rows('groups')).single['name'], '家族');
  });
}
