import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/repositories/dvc/sqlite_dvc_point_contract_repository.dart';

void main() {
  test('契約を編集してもIDを維持し重複登録しない', () async {
    final db = OfflineDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertRow('members', {'id': 'm1', 'display_name': '本人'});
    await db.insertRow('groups', {'id': 'g1', 'owner_id': 'm1', 'name': '家族'});
    final repository = SqliteDvcPointContractRepository(db);
    final contract = DvcPointContract(
      id: 'c1', groupId: 'g1', contractName: '契約A',
      contractStartYearMonth: DateTime(2025, 10),
      contractEndYearMonth: DateTime(2025, 10),
      useYearStartMonth: 10, annualPoint: 60,
    );
    await repository.saveDvcPointContract(contract);
    await repository.saveDvcPointContract(contract.copyWith(contractName: '編集後'));
    final rows = await db.rows('dvc_point_contracts');
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'c1');
    expect(rows.single['contract_name'], '編集後');
  });
}
