import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_point_contract_mapper.dart';

class SqliteDvcPointContractRepository implements DvcPointContractRepository {
  SqliteDvcPointContractRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<void> saveDvcPointContract(DvcPointContract value) async {
    if (value.id.isEmpty) {
      await db.insertRow(
        'dvc_point_contracts',
        SqliteDvcPointContractMapper.toRow(
          value.copyWith(id: const Uuid().v4()),
        ),
      );
      return;
    }
    final existing = await db.rows(
      'dvc_point_contracts',
      where: 'id = ?',
      args: [value.id],
    );
    final row = SqliteDvcPointContractMapper.toRow(value);
    if (existing.isEmpty) {
      await db.insertRow('dvc_point_contracts', row);
    } else {
      await db.updateRow('dvc_point_contracts', value.id, row);
    }
  }

  @override
  Future<void> saveDvcPointContracts(
    String groupId,
    List<DvcPointContract> contracts, {
    Map<String, int> expectedVersions = const {},
  }) async {
    await db.transaction(() async {
      final existing = await db.rows(
        'dvc_point_contracts',
        where: 'group_id = ?',
        args: [groupId],
      );
      final retainedIds = contracts.map((v) => v.id).toSet();
      for (final row in existing) {
        final id = row['id'] as String;
        if (!retainedIds.contains(id)) await deleteDvcPointContract(id);
      }
      for (final contract in contracts) {
        await saveDvcPointContract(contract);
      }
    });
  }

  @override
  Future<void> deleteDvcPointContract(String id, {int? expectedVersion}) async {
    for (final table in ['dvc_point_usages', 'dvc_limited_points']) {
      if ((await db.rows(
        table,
        where: 'contract_id = ?',
        args: [id],
      )).isNotEmpty) {
        throw StateError('利用履歴・期間限定ポイントがある契約は削除できません');
      }
    }
    await db.deleteRows('dvc_point_contracts', 'id', id);
  }

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) =>
      saveDvcPointContracts(groupId, []);
}
