import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_usage_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firestore_dvc_point_usage_repository_test.mocks.dart';

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
  group('FirestoreDvcPointUsageRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreDvcPointUsageRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('dvc_point_usages'),
      ).thenReturn(mockCollection);
      repository = FirestoreDvcPointUsageRepository(firestore: mockFirestore);
    });

    test('saveがdvc_point_usagesに追加する', () async {
      final usage = DvcPointUsage(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
        memo: 'ホテル',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveDvcPointUsage(usage);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('usedPoint', 60),
              containsPair('memo', 'ホテル'),
              contains('usageYearMonth'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('deleteが指定IDのドキュメントを削除する', () async {
      const id = 'usage001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(id)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteDvcPointUsage(id);

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

      await repository.deleteDvcPointUsagesByGroupId(groupId);

      verify(mockBatch.delete(mockDocRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
