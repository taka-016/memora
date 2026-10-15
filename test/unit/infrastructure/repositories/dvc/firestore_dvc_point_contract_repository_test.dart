import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_contract_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_dvc_point_contract_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  WriteBatch,
])
void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference<Map<String, dynamic>> collection;
  late MockWriteBatch batch;
  late FirestoreDvcPointContractRepository repository;
  final contract = DvcPointContract(
    id: 'c1',
    groupId: 'g1',
    contractName: '契約A',
    contractStartYearMonth: DateTime(2025, 10),
    contractEndYearMonth: DateTime(2025, 10),
    useYearStartMonth: 10,
    annualPoint: 60,
  );
  final references = <String, MockDocumentReference<Map<String, dynamic>>>{};
  void stubChildren(String name, {bool hasChild = false}) {
    final childCollection = MockCollectionReference<Map<String, dynamic>>();
    final query = MockQuery<Map<String, dynamic>>();
    final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
    when(firestore.collection(name)).thenReturn(childCollection);
    when(childCollection.where('contractId', isEqualTo: anyNamed('isEqualTo')))
        .thenReturn(query);
    when(query.limit(1)).thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    when(snapshot.docs).thenReturn(
      hasChild ? [MockQueryDocumentSnapshot<Map<String, dynamic>>()] : [],
    );
  }

  setUp(() {
    firestore = MockFirebaseFirestore();
    collection = MockCollectionReference<Map<String, dynamic>>();
    batch = MockWriteBatch();
    references.clear();
    when(firestore.collection('dvc_point_contracts')).thenReturn(collection);
    when(collection.doc(any)).thenAnswer(
      (call) => references.putIfAbsent(
        call.positionalArguments.first as String? ?? 'new',
        () => MockDocumentReference<Map<String, dynamic>>(),
      ),
    );
    when(firestore.batch()).thenReturn(batch);
    when(batch.commit()).thenAnswer((_) async {});
    final query = MockQuery<Map<String, dynamic>>();
    final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final doc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    when(collection.where('groupId', isEqualTo: 'g1')).thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    when(snapshot.docs).thenReturn([doc]);
    when(doc.id).thenReturn('c1');
    when(doc.reference).thenAnswer((_) => collection.doc('c1'));
    stubChildren('dvc_point_usages');
    stubChildren('dvc_limited_points');
    repository = FirestoreDvcPointContractRepository(firestore: firestore);
  });

  test('単独保存でも既存IDを指定して保存する', () async {
    final reference = references.putIfAbsent('c1', () => MockDocumentReference<Map<String, dynamic>>());
    when(reference.set(any, any)).thenAnswer((_) async {});
    await repository.saveDvcPointContract(contract);
    verify(reference.set(argThat(containsPair('contractName', '契約A')), any))
        .called(1);
    verifyNever(collection.add(any));
  });

  test('契約一覧の変更・追加を同じバッチで保存し既存IDを削除しない', () async {
    await repository.saveDvcPointContracts('g1', [
      contract,
      contract.copyWith(id: '', contractName: '追加'),
    ]);
    verify(
      batch.update(
        collection.doc('c1'),
        argThat(containsPair('contractName', '契約A')),
      ),
    ).called(1);
    verify(
      batch.set(collection.doc(), argThat(containsPair('contractName', '追加'))),
    ).called(1);
    verifyNever(batch.delete(any));
    verify(batch.commit()).called(1);
  });

  for (final kind in ['dvc_point_usages', 'dvc_limited_points']) {
    test('$kindがある契約の削除は一覧保存・単独削除とも拒否する', () async {
      stubChildren(kind, hasChild: true);
      await expectLater(
        repository.saveDvcPointContracts('g1', []),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.deleteDvcPointContract('c1'),
        throwsA(isA<StateError>()),
      );
      verifyNever(batch.commit());
    });
  }

  test('子がない契約を同一バッチで削除する', () async {
    await repository.saveDvcPointContracts('g1', []);
    verify(batch.delete(collection.doc('c1'))).called(1);
    verify(batch.commit()).called(1);
  });

  test('保存が失敗すると成功扱いにせず例外を返す', () async {
    when(batch.commit()).thenThrow(TestException('保存失敗'));
    await expectLater(
      repository.saveDvcPointContracts('g1', [contract]),
      throwsA(isA<TestException>()),
    );
    verify(batch.commit()).called(1);
  });
}
