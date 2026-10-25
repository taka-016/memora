import 'package:memora/infrastructure/queries/group/sqlite_group_query_service.dart';
import 'package:memora/infrastructure/queries/member/sqlite_member_query_service.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';
import 'package:memora/infrastructure/repositories/member/sqlite_member_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

void main() {
  late OfflineDatabase db;
  setUp(() => db = OfflineDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('親の全項目を元のIDで退避先へ保存できる', () async {
    final member = <String, Object?>{
      'id': 'member',
      'account_id': 'account',
      'owner_id': 'owner',
      'hiragana_first_name': 'たろう',
      'hiragana_last_name': 'やまだ',
      'kanji_first_name': '太郎',
      'kanji_last_name': '山田',
      'first_name': 'Taro',
      'last_name': 'Yamada',
      'display_name': '太郎',
      'type': '家族',
      'birthday': 123456789,
      'gender': '男性',
      'email': 'taro@example.com',
      'phone_number': '09012345678',
    };
    final group = <String, Object?>{
      'id': 'group',
      'owner_id': 'owner',
      'name': '家族',
      'memo': null,
      'color': '#4CAF50',
    };
    await db.insertRow('deleted_members', member);
    await db.insertRow('deleted_groups', group);
    expect(await db.rows('deleted_members'), [member]);
    expect(await db.rows('deleted_groups'), [group]);
    expect(await db.rows('members'), isEmpty);
    expect(await db.rows('groups'), isEmpty);
  });

  test('通常の親を削除しても関連行と元の参照IDをすべて保持する', () async {
    final rows = <String, List<Map<String, Object?>>>{
      'members': [
        {'id': 'owner', 'display_name': '本人'},
        {'id': 'member', 'owner_id': 'owner', 'display_name': '家族'},
      ],
      'groups': [
        {'id': 'group', 'owner_id': 'owner', 'name': '家族'},
      ],
      'group_members': [
        {
          'group_id': 'group',
          'member_id': 'member',
          'is_administrator': 1,
          'order_index': 3,
        },
      ],
      'trip_entries': [
        {'id': 'trip', 'group_id': 'group', 'year': 2026},
      ],
      'tasks': [
        {
          'id': 'task',
          'trip_id': 'trip',
          'name': '準備',
          'order_index': 0,
          'is_completed': 0,
          'assigned_member_id': 'member',
        },
      ],
      'itinerary_items': [
        {'id': 'item', 'trip_id': 'trip', 'name': '出発'},
      ],
      'member_events': [
        {'id': 'me', 'member_id': 'member', 'year': 2026, 'memo': '入学'},
      ],
      'group_events': [
        {'id': 'ge', 'group_id': 'group', 'year': 2026, 'memo': '記念'},
      ],
      'calendar_labels': [
        {'id': 'label', 'group_id': 'group', 'name': '全員', 'color': '#123456'},
      ],
      'calendar_events': [
        {
          'id': 'event',
          'group_id': 'group',
          'label_id': 'label',
          'label_type': 'custom',
          'title': '予定',
          'start_date_time': 1,
          'end_date_time': 2,
          'is_all_day': 1,
          'recurrence_rule': 'FREQ=DAILY',
        },
      ],
      'calendar_event_overrides': [
        {
          'event_id': 'event',
          'group_id': 'group',
          'original_start_date_time': 1,
          'is_cancelled': 1,
        },
      ],
      'dvc_point_contracts': [
        {
          'id': 'contract',
          'group_id': 'group',
          'contract_name': '契約',
          'contract_start_year_month': 1,
          'contract_end_year_month': 2,
          'use_year_start_month': 1,
          'annual_point': 100,
        },
      ],
      'dvc_limited_points': [
        {
          'id': 'limited',
          'group_id': 'group',
          'contract_id': 'contract',
          'start_year_month': 1,
          'end_year_month': 2,
          'point': 10,
        },
      ],
      'dvc_point_usages': [
        {
          'id': 'usage',
          'group_id': 'group',
          'contract_id': 'contract',
          'usage_year_month': 1,
          'used_point': 5,
        },
      ],
    };
    for (final table in rows.entries) {
      for (final row in table.value) {
        await db.insertRow(table.key, row);
      }
    }
    final before = {for (final table in rows.keys) table: await db.rows(table)};
    await SqliteGroupRepository(db).deleteGroup('group');
    expect((await db.rows('deleted_groups')).single, before['groups']!.single);
    await SqliteMemberRepository(db).deleteMember('member');
    expect((await db.rows('deleted_members')).single, before['members']!.last);
    await db.deleteRows('members', 'id', 'owner');
    expect(await db.rows('members'), isEmpty);
    expect(await db.rows('groups'), isEmpty);
    expect(
      await SqliteGroupQueryService(db)
          .getGroupsWithMembersByMemberId('member'),
      isEmpty,
    );
    expect(
      await SqliteGroupQueryService(db)
          .getManagedGroupsWithMembersByOwnerId('owner'),
      isEmpty,
    );
    expect(await SqliteMemberQueryService(db).getMemberById('member'), isNull);
    for (final table in rows.keys.where(
      (t) => t != 'members' && t != 'groups',
    )) {
      expect(await db.rows(table), before[table], reason: table);
    }
    // 別の通常グループ・メンバーも退避済みの所有者IDを維持できる。
    await db.insertRow('groups', {
      'id': 'other',
      'owner_id': 'owner',
      'name': '別グループ',
    });
    await db.insertRow('members', {
      'id': 'other',
      'owner_id': 'owner',
      'display_name': '別メンバー',
    });
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
