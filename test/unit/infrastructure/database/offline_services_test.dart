import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/repositories/member/sqlite_member_repository.dart';
import 'package:memora/infrastructure/repositories/member/sqlite_member_event_repository.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_event_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/queries/member/sqlite_member_query_service.dart';
import 'package:memora/infrastructure/queries/member/sqlite_member_event_query_service.dart';
import 'package:memora/infrastructure/queries/group/sqlite_group_event_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/sqlite_dvc_point_contract_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/sqlite_dvc_limited_point_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/sqlite_dvc_point_usage_query_service.dart';
import 'package:memora/infrastructure/services/local_current_member_resolver.dart';
import 'package:memora/infrastructure/services/sqlite_current_member_resolver.dart';

void main() {
  late OfflineDatabase db;
  late Directory directory;
  late String memberId;
  late String groupId;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('memora-sqlite-');
    db = OfflineDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
    final member = await SqliteCurrentMemberResolver(
      db,
      localResolver: LocalCurrentMemberResolver(
        directory: () async => directory,
      ),
    ).resolve();
    memberId = member.id;
    groupId = await SqliteGroupRepository(db)
        .saveGroup(Group(id: '', ownerId: memberId, name: '家族'));
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('既存JSONの本人IDを維持し編集結果をDB再オープン後に復元する', () async {
    final local = LocalCurrentMemberResolver(directory: () async => directory);
    final original = await local.resolve();
    expect(memberId, original.id);
    final birthday = DateTime(2000, 2, 29);
    await SqliteMemberRepository(db).updateMember(
      Member(
        id: memberId,
        accountId: original.accountId,
        displayName: '変更した本人',
        birthday: birthday,
      ),
    );
    await db.close();
    db = OfflineDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
    final restored = await SqliteCurrentMemberResolver(
      db,
      localResolver: local,
    ).resolve();
    expect(restored.id, original.id);
    expect(restored.accountId, original.accountId);
    expect(restored.displayName, '変更した本人');
    expect(restored.birthday, birthday);
    expect((await SqliteMemberQueryService(db).getMembers()).length, 1);
  });

  test('メンバーの検索と並び替えおよびnullable項目の解除を保存する', () async {
    final repo = SqliteMemberRepository(db);
    final query = SqliteMemberQueryService(db);
    await repo.saveMember(
      Member(
        id: '',
        ownerId: memberId,
        displayName: 'B',
        email: 'b@example.com',
      ),
    );
    await repo.saveMember(Member(id: '', ownerId: memberId, displayName: 'A'));
    final members = await query.getMembersByOwnerId(
      memberId,
      orderBy: [const OrderBy('displayName')],
    );
    expect(members.map((m) => m.displayName), ['A', 'B']);
    await repo.updateMember(
      Member(id: members.last.id, ownerId: memberId, displayName: 'B'),
    );
    expect((await query.getMemberById(members.last.id))!.email, isNull);
    await repo.deleteMember(members.first.id);
    expect(await query.getMemberById(members.first.id), isNull);
  });

  test('同年のメンバーイベントは置換し空メモで削除する', () async {
    final repo = SqliteMemberEventRepository(db);
    final query = SqliteMemberEventQueryService(db);
    final event = MemberEvent(
      id: '',
      memberId: memberId,
      year: 2026,
      memo: '入学',
    );
    final id = await repo.saveMemberEvent(event);
    expect(await repo.saveMemberEvent(event.copyWith(memo: '卒業')), id);
    await repo.saveMemberEvent(event.copyWith(year: 2025));
    final events = await query.getMemberEventsByMemberIds(
      [memberId, memberId],
      orderBy: [const OrderBy('year', descending: true)],
    );
    expect(events.map((e) => e.year), [2026, 2025]);
    expect(events.first.memo, '卒業');
    expect(await repo.saveMemberEvent(event.copyWith(memo: '')), '');
    expect(
      (await query.getMemberEventsByMemberIds([memberId])).single.year,
      2025,
    );
    await repo.deleteMemberEventsByMemberId(memberId);
    expect(await query.getMemberEventsByMemberIds([memberId]), isEmpty);
    expect(await query.getMemberEventsByMemberIds([]), isEmpty);
  });

  test('グループイベントは同年の複数件を保持し指定IDだけ更新する', () async {
    final repo = SqliteGroupEventRepository(db);
    final query = SqliteGroupEventQueryService(db);
    final event = GroupEvent(id: '', groupId: groupId, year: 2026, memo: '行事');
    final id = await repo.saveGroupEvent(event);
    await repo.saveGroupEvent(event);
    await repo.saveGroupEvent(event.copyWith(id: id, memo: '変更'));
    expect((await query.getGroupEventsByGroupId(groupId)).length, 2);
    await repo.deleteGroupEvent(id);
    expect((await query.getGroupEventsByGroupId(groupId)).single.memo, '行事');
    await repo.deleteGroupEventsByGroupId(groupId);
    expect(await query.getGroupEventsByGroupId(groupId), isEmpty);
  });

  test('DVCの契約と期間限定ポイントと利用履歴を保存取得削除する', () async {
    final start = DateTime(2026, 1);
    final end = DateTime(2026, 12);
    final contracts = SqliteDvcPointContractRepository(db);
    final limited = SqliteDvcLimitedPointRepository(db);
    final usages = SqliteDvcPointUsageRepository(db);
    await contracts.saveDvcPointContract(
      DvcPointContract(
        id: '',
        groupId: groupId,
        contractName: '契約',
        contractStartYearMonth: start,
        contractEndYearMonth: end,
        useYearStartMonth: 4,
        annualPoint: 100,
      ),
    );
    await limited.saveDvcLimitedPoint(
      DvcLimitedPoint(
        id: '',
        groupId: groupId,
        startYearMonth: start,
        endYearMonth: end,
        point: 30,
        memo: '追加',
      ),
    );
    await usages.saveDvcPointUsage(
      DvcPointUsage(
        id: '',
        groupId: groupId,
        usageYearMonth: start,
        usedPoint: 10,
      ),
    );
    final contract = (await SqliteDvcPointContractQueryService(
      db,
    ).getDvcPointContractsByGroupId(groupId)).single;
    final point = (await SqliteDvcLimitedPointQueryService(
      db,
    ).getDvcLimitedPointsByGroupId(groupId)).single;
    final usage = (await SqliteDvcPointUsageQueryService(
      db,
    ).getDvcPointUsagesByGroupId(groupId)).single;
    expect(contract.contractStartYearMonth, start);
    expect(contract.annualPoint, 100);
    expect(point.endYearMonth, end);
    expect(point.point, 30);
    expect(usage.usageYearMonth, start);
    expect(usage.usedPoint, 10);
    expect(usage.memo, isNull);
    await contracts.deleteDvcPointContract(contract.id);
    await limited.deleteDvcLimitedPoint(point.id);
    await usages.deleteDvcPointUsage(usage.id);
    expect(
      await SqliteDvcPointContractQueryService(db)
          .getDvcPointContractsByGroupId(groupId),
      isEmpty,
    );
    expect(
      await SqliteDvcLimitedPointQueryService(db)
          .getDvcLimitedPointsByGroupId(groupId),
      isEmpty,
    );
    expect(
      await SqliteDvcPointUsageQueryService(db)
          .getDvcPointUsagesByGroupId(groupId),
      isEmpty,
    );
  });
}
