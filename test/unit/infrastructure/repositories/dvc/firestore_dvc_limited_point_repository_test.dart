import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_limited_point_repository.dart';

import '../../../../helpers/firestore_transaction_store.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  late FirestoreTransactionStore store;
  late FirestoreDvcLimitedPointRepository repository;
  final value = DvcLimitedPoint(
    id: 'child',
    groupId: 'g1',
    contractId: 'c1',
    startYearMonth: DateTime(2025, 7),
    endYearMonth: DateTime(2025, 12),
    point: 30,
  );
  setUp(() {
    store = FirestoreTransactionStore();
    store.rows['dvc_point_contracts/c1'] = {'version': 3, 'groupId': 'g1'};
    store.rows['groups/g1'] = {'version': 8};
    repository = FirestoreDvcLimitedPointRepository(firestore: store.firestore);
  });
  test('追加と変更は契約の期待バージョンと同じバッチで保存する', () async {
    await repository.saveDvcLimitedPoint(value, expectedContractVersion: 3);
    expect(store.rows['dvc_point_contracts/c1']!['version'], 4);
    expect(store.rows['dvc_limited_points/child']!['contractId'], 'c1');
    await repository.saveDvcLimitedPoint(value, expectedContractVersion: 4);
    expect(store.rows['dvc_point_contracts/c1']!['version'], 5);
    expect(
      store.rows.keys.where((key) => key.startsWith('dvc_limited_points/')),
      hasLength(1),
    );
    expect(store.rows['groups/g1']!['version'], 8);
  });
  test('削除は取得時の契約バージョンを照合し契約を更新する', () async {
    store.rows['dvc_limited_points/child'] = {
      'contractId': 'c1',
      'groupId': 'g1',
    };
    await repository.deleteDvcLimitedPoint('child', expectedContractVersion: 3);
    expect(store.rows.keys, isNot(contains('dvc_limited_points/child')));
    expect(store.rows['dvc_point_contracts/c1']!['version'], 4);
  });
  for (final expected in [null, 2]) {
    test('古い期待値$expectedの削除は親子を保持する', () async {
      store.rows['dvc_limited_points/child'] = {'contractId': 'c1'};
      await expectLater(
        repository.deleteDvcLimitedPoint(
          'child',
          expectedContractVersion: expected,
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'aborted'),
        ),
      );
      expect(store.rows['dvc_point_contracts/c1']!['version'], 3);
      expect(store.rows.keys, contains('dvc_limited_points/child'));
    });
  }
  test('保存失敗では契約も子も変更しない', () async {
    store.commitError = TestException('保存失敗');
    await expectLater(
      repository.saveDvcLimitedPoint(value, expectedContractVersion: 3),
      throwsA(isA<TestException>()),
    );
    expect(store.rows['dvc_point_contracts/c1']!['version'], 3);
    expect(store.rows.keys, isNot(contains('dvc_limited_points/child')));
  });
  test('削除の再試行で期待値を差し替えない', () async {
    store.rows['dvc_limited_points/child'] = {'contractId': 'c1'};
    store.beforeRetry = () =>
        store.rows['dvc_point_contracts/c1']!['version'] = 4;
    await expectLater(
      repository.deleteDvcLimitedPoint('child', expectedContractVersion: 3),
      throwsA(
        isA<FirebaseException>().having((e) => e.code, 'code', 'aborted'),
      ),
    );
    expect(store.rows.keys, contains('dvc_limited_points/child'));
  });
  test('グループ内の一括削除も契約ごとに一度だけ更新する', () async {
    for (final id in ['a', 'b']) {
      store.rows['dvc_limited_points/$id'] = {
        'contractId': 'c1',
        'groupId': 'g1',
      };
    }
    await repository.deleteDvcLimitedPointsByGroupId('g1');
    expect(store.rows['dvc_point_contracts/c1']!['version'], 4);
    expect(
      store.rows.keys.where((key) => key.startsWith('dvc_limited_points/')),
      isEmpty,
    );
  });
}
