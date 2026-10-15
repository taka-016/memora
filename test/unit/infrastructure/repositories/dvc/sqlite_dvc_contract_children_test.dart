import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/queries/dvc/sqlite_dvc_point_usage_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/sqlite_dvc_limited_point_query_service.dart';

void main() {
  late OfflineDatabase db;
  late SqliteDvcPointContractRepository repository;
  final month = DateTime(2025, 10);
  DvcPointContract contract(String id) => DvcPointContract(
    id: id,
    groupId: 'g1',
    contractName: id,
    contractStartYearMonth: month,
    contractEndYearMonth: month,
    useYearStartMonth: 10,
    annualPoint: 60,
  );
  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    await db.insertRow('members', {'id': 'm1', 'display_name': '本人'});
    await db.insertRow('groups', {'id': 'g1', 'owner_id': 'm1', 'name': '家族'});
    repository = SqliteDvcPointContractRepository(db);
    await repository.saveDvcPointContracts('g1', [
      contract('a'),
      contract('b'),
    ]);
  });
  tearDown(() => db.close());

  Future<void> addUsage(String id) => SqliteDvcPointUsageRepository(db)
      .saveDvcPointUsage(
        DvcPointUsage(
          id: '',
          groupId: 'g1',
          contractId: id,
          usageYearMonth: month,
          usedPoint: 20,
        ),
      );
  Future<void> addLimited(String id) =>
      SqliteDvcLimitedPointRepository(db).saveDvcLimitedPoint(
        DvcLimitedPoint(
          id: '',
          groupId: 'g1',
          contractId: id,
          startYearMonth: month,
          endYearMonth: month,
          point: 30,
        ),
      );

  test('契約ごとに利用と期間限定ポイントを取得し編集後も紐付けを維持する', () async {
    await addUsage('a');
    await addUsage('b');
    await addLimited('a');
    await addLimited('b');
    await repository.saveDvcPointContracts('g1', [
      contract('a').copyWith(contractName: '編集後'),
      contract('b'),
    ]);
    final usages = await SqliteDvcPointUsageQueryService(db)
        .getDvcPointUsagesByGroupId('g1', contractId: 'a');
    final limited = await SqliteDvcLimitedPointQueryService(db)
        .getDvcLimitedPointsByGroupId('g1', contractId: 'b');
    expect(usages.single.contractId, 'a');
    expect(limited.single.contractId, 'b');
    expect(await db.rows('dvc_point_contracts'), hasLength(2));
    expect(
      await SqliteDvcPointUsageQueryService(db)
          .getDvcPointUsagesByGroupId('g1'),
      hasLength(2),
    );
  });

  for (final kind in ['利用履歴', '期間限定ポイント']) {
    test('$kindがある契約の削除を拒否し他契約の変更も保存しない', () async {
      if (kind == '利用履歴') {
        await addUsage('a');
      } else {
        await addLimited('a');
      }
      await expectLater(
        repository.saveDvcPointContracts('g1', [
          contract('b').copyWith(contractName: '変更'),
        ]),
        throwsA(isA<StateError>()),
      );
      final rows = await db.rows('dvc_point_contracts');
      expect(rows, hasLength(2));
      expect(rows.firstWhere((v) => v['id'] == 'b')['contract_name'], 'b');
      await expectLater(
        repository.deleteDvcPointContract('a'),
        throwsA(isA<StateError>()),
      );
    });
  }

  test('保存途中でSQLが失敗しても追加と削除をロールバックする', () async {
    await db.customStatement(
      "CREATE TRIGGER reject_dvc BEFORE INSERT ON dvc_point_contracts WHEN NEW.id = 'fail' BEGIN SELECT RAISE(ABORT, '保存失敗'); END",
    );
    await expectLater(
      repository.saveDvcPointContracts('g1', [
        contract('new'),
        contract('fail'),
      ]),
      throwsA(anything),
    );
    expect(
      (await db.rows('dvc_point_contracts')).map((v) => v['id']),
      unorderedEquals(['a', 'b']),
    );
  });

  test('子のない契約を削除し初回作成と空一覧の保存ができる', () async {
    await repository.saveDvcPointContracts('g1', []);
    expect(await db.rows('dvc_point_contracts'), isEmpty);
    await repository.saveDvcPointContracts('g1', [
      contract('').copyWith(contractName: '初回'),
    ]);
    final rows = await db.rows('dvc_point_contracts');
    expect(rows.single['id'], isNotEmpty);
    expect(rows.single['contract_name'], '初回');
  });
}
