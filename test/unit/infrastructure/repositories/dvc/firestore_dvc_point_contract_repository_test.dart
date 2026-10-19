import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_contract_repository.dart';
import '../../../../helpers/firestore_transaction_store.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  late FirestoreTransactionStore store;
  late FirestoreDvcPointContractRepository repository;
  final contract = DvcPointContract(id: 'c1', groupId: 'g1', contractName: '契約A',
    contractStartYearMonth: DateTime(2025, 10), contractEndYearMonth: DateTime(2026, 10),
    useYearStartMonth: 10, annualPoint: 60);
  setUp(() {
    store = FirestoreTransactionStore();
    repository = FirestoreDvcPointContractRepository(firestore: store.firestore);
    store.rows['groups/g1'] = {'version': 7};
  });
  test('初回契約を作成しグループのバージョンは変更しない', () async {
    await repository.saveDvcPointContract(contract);
    expect(store.rows['dvc_point_contracts/c1']!['version'], 1);
    expect(store.rows['groups/g1']!['version'], 7);
  });
  test('契約一覧で編集・新規追加・削除を同じ処理へまとめる', () async {
    store.rows['dvc_point_contracts/c1'] = {'groupId': 'g1', 'version': 3};
    store.rows['dvc_point_contracts/deleted'] = {'groupId': 'g1', 'version': 5};
    await repository.saveDvcPointContracts('g1', [contract.copyWith(version: 3), contract.copyWith(id: 'new')],
      expectedVersions: {'c1': 3, 'deleted': 5});
    expect(store.rows['dvc_point_contracts/c1']!['version'], 4);
    expect(store.rows['dvc_point_contracts/new']!['version'], 1);
    expect(store.rows.keys, isNot(contains('dvc_point_contracts/deleted')));
    expect(store.commits, 1);
  });
  test('削除対象の期待値が古ければ一覧全体を変更しない', () async {
    store.rows['dvc_point_contracts/deleted'] = {'groupId': 'g1', 'version': 5};
    await expectLater(repository.saveDvcPointContracts('g1', [contract], expectedVersions: {'deleted': 4}),
      throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'aborted')));
    expect(store.rows.keys, isNot(contains('dvc_point_contracts/c1')));
    expect(store.rows.keys, contains('dvc_point_contracts/deleted'));
  });
  for (final collection in ['dvc_point_usages', 'dvc_limited_points']) {
    test('$collectionがある契約の削除を拒否する', () async {
      store.rows['dvc_point_contracts/c1'] = {'groupId': 'g1', 'version': 3};
      store.rows['$collection/child'] = {'contractId': 'c1'};
      await expectLater(repository.saveDvcPointContracts('g1', [], expectedVersions: {'c1': 3}), throwsA(isA<StateError>()));
      await expectLater(repository.deleteDvcPointContract('c1', expectedVersion: 3), throwsA(isA<StateError>()));
      expect(store.rows.keys, contains('dvc_point_contracts/c1'));
    });
  }
  test('一覧保存の途中失敗では作成も削除も反映しない', () async {
    store.rows['dvc_point_contracts/deleted'] = {'groupId': 'g1', 'version': 5};
    store.commitError = TestException('保存失敗');
    await expectLater(repository.saveDvcPointContracts('g1', [contract], expectedVersions: {'deleted': 5}), throwsA(isA<TestException>()));
    expect(store.rows.keys, isNot(contains('dvc_point_contracts/c1')));
    expect(store.rows.keys, contains('dvc_point_contracts/deleted'));
  });
}
