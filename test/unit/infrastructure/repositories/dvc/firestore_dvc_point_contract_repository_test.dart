import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_contract_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
  group('FirestoreDvcPointContractRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreDvcPointContractRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('dvc_point_contracts'),
      ).thenReturn(mockCollection);
      repository = FirestoreDvcPointContractRepository(
        firestore: mockFirestore,
      );
    });

    test('saveがdvc_point_contractsに追加する', () async {
      final contract = DvcPointContract(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveDvcPointContract(contract);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('contractName', '契約A'),
              containsPair('useYearStartMonth', 10),
              containsPair('annualPoint', 200),
              contains('contractStartYearMonth'),
              contains('contractEndYearMonth'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('deleteが指定IDのドキュメントを削除する', () async {
      const id = 'contract001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(id)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteDvcPointContract(id);

      verify(mockCollection.doc(id)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('deleteByGroupIdが指定groupIdのドキュメントを一括削除する', () async {
      const groupId = 'group001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.reference).thenReturn(mockDocRef);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteDvcPointContractsByGroupId(groupId);

      verify(mockBatch.delete(mockDocRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
