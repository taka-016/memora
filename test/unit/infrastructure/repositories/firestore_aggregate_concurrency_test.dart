import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/transactions/firestore_write_transaction.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_contract_repository.dart';

import '../../../helpers/firestore_transaction_store.dart';
import '../../../helpers/test_exception.dart';

void main() {
  late FirestoreTransactionStore store;
  setUp(() {
    store = FirestoreTransactionStore();
    store.rows.addAll({
      'trip_entries/t1': {'version': 3, 'groupId': 'g1'},
      'locations/l1': {'tripId': 't1'},
      'tasks/k1': {'tripId': 't1'},
      'itinerary_items/i1': {'tripId': 't1'},
      'groups/g1': {'version': 3, 'name': '家族'},
      'group_members/m1': {'groupId': 'g1', 'memberId': 'm1'},
      'dvc_point_contracts/c1': {'version': 3, 'groupId': 'g1'},
    });
  });

  Matcher getConflict() =>
      isA<FirebaseException>().having((error) => error.code, 'code', 'aborted');

  for (final expected in [null, 2]) {
    test('旅行の期待値$expectedでは親子を削除しない', () async {
      final before = Map.of(store.rows);
      await expectLater(
        FirestoreTripEntryRepository(firestore: store.firestore)
            .deleteTripEntry('t1', expectedVersion: expected),
        throwsA(getConflict()),
      );
      expect(store.rows, before);
    });
    test('グループの期待値$expectedでは退避も所属変更もしない', () async {
      final before = Map.of(store.rows);
      await expectLater(
        FirestoreGroupRepository(firestore: store.firestore)
            .deleteGroup('g1', expectedVersion: expected),
        throwsA(getConflict()),
      );
      expect(store.rows, before);
    });
    test('DVC契約の期待値$expectedでは削除しない', () async {
      await expectLater(
        FirestoreDvcPointContractRepository(firestore: store.firestore)
            .deleteDvcPointContract('c1', expectedVersion: expected),
        throwsA(getConflict()),
      );
      expect(store.rows['dvc_point_contracts/c1']!['version'], 3);
    });
  }

  test('旅行の削除は親子を一括削除し別の旅行を保持する', () async {
    store.rows['tasks/other'] = {'tripId': 't2'};
    await FirestoreTripEntryRepository(firestore: store.firestore)
        .deleteTripEntry('t1', expectedVersion: 3);
    expect(store.rows.keys, isNot(contains('trip_entries/t1')));
    for (final path in ['locations/l1', 'tasks/k1', 'itinerary_items/i1']) {
      expect(store.rows.keys, isNot(contains(path)));
    }
    expect(store.rows['tasks/other'], {'tripId': 't2'});
    expect(store.commits, 1);
  });

  test('旅行の削除の再試行は最初の期待値を維持する', () async {
    store.beforeRetry = () => store.rows['trip_entries/t1']!['version'] = 4;
    await expectLater(
      FirestoreTripEntryRepository(firestore: store.firestore)
          .deleteTripEntry('t1', expectedVersion: 3),
      throwsA(getConflict()),
    );
    expect(store.rows.keys, contains('locations/l1'));
    expect(store.commits, 0);
  });

  test('親子の削除途中に失敗した場合は全件を保持する', () async {
    store.commitError = TestException('保存失敗');
    final before = Map.of(store.rows);
    await expectLater(
      FirestoreTripEntryRepository(firestore: store.firestore)
          .deleteTripEntry('t1', expectedVersion: 3),
      throwsA(isA<TestException>()),
    );
    expect(store.rows, before);
  });

  test('グループはバージョンを含めて退避し所属とDVC契約を保持する', () async {
    await FirestoreGroupRepository(firestore: store.firestore)
        .deleteGroup('g1', expectedVersion: 3);
    expect(store.rows['deleted_groups/g1'], {'version': 3, 'name': '家族'});
    expect(store.rows.keys, isNot(contains('groups/g1')));
    expect(
      store.rows.keys,
      containsAll(['group_members/m1', 'dvc_point_contracts/c1']),
    );
  });

  test('DVC契約削除の再試行でも期待値を維持する', () async {
    store.beforeRetry = () =>
        store.rows['dvc_point_contracts/c1']!['version'] = 4;
    await expectLater(
      FirestoreDvcPointContractRepository(firestore: store.firestore)
          .deleteDvcPointContract('c1', expectedVersion: 3),
      throwsA(getConflict()),
    );
    expect(store.rows.keys, contains('dvc_point_contracts/c1'));
  });
  test('旅行の子だけの変更も親の期待値から更新する', () async {
    await FirestoreTripEntryRepository(firestore: store.firestore)
        .updateTripEntry(
          TripEntry(
            id: 't1',
            groupId: 'g1',
            year: 2025,
            version: 3,
            tasks: [
              Task(
                id: 'k2',
                tripId: 't1',
                name: '準備',
                orderIndex: 0,
                isCompleted: false,
              ),
            ],
          ),
        );
    expect(store.rows['trip_entries/t1']!['version'], 4);
    expect(store.rows.keys, isNot(contains('tasks/k1')));
    expect(store.rows['tasks/k2']!['tripId'], 't1');
    expect(store.commits, 1);
  });

  test('共有トランザクションでも複数旅行の親照合後に親子を削除する', () async {
    store.rows['trip_entries/t2'] = {'version': 5, 'groupId': 'g1'};
    await FirestoreWriteTransaction(firestore: store.firestore)
        .run<void>((scope) async {
          final repo = scope.repository<TripEntryRepository>();
          await repo.deleteTripEntry('t1', expectedVersion: 3);
          await repo.deleteTripEntry('t2', expectedVersion: 5);
        });
    expect(
      store.rows.keys.where((key) => key.startsWith('trip_entries/')),
      isEmpty,
    );
    expect(store.commits, 1);
  });

  test('グループ内の旅行の一括削除も親を照合して同一トランザクションで削除する', () async {
    store.rows['trip_entries/t2'] = {'version': 5, 'groupId': 'g1'};
    await FirestoreTripEntryRepository(firestore: store.firestore)
        .deleteTripEntriesByGroupId('g1');
    expect(store.reads, containsAll(['trip_entries/t1', 'trip_entries/t2']));
    expect(
      store.rows.keys.where((key) => key.startsWith('trip_entries/')),
      isEmpty,
    );
    expect(store.commits, 1);
  });
}
