import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_limited_point_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firestore_dvc_limited_point_repository_test.mocks.dart';

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
  group('FirestoreDvcLimitedPointRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreDvcLimitedPointRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('dvc_limited_points'),
      ).thenReturn(mockCollection);
      repository = FirestoreDvcLimitedPointRepository(firestore: mockFirestore);
    });

    test('saveがdvc_limited_pointsに追加する', () async {
      final point = DvcLimitedPoint(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
        memo: '追加分',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveDvcLimitedPoint(point);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('point', 30),
              containsPair('memo', '追加分'),
              contains('startYearMonth'),
              contains('endYearMonth'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('deleteが指定IDのドキュメントを削除する', () async {
      const id = 'limited001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(id)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteDvcLimitedPoint(id);

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

      await repository.deleteDvcLimitedPointsByGroupId(groupId);

      verify(mockBatch.delete(mockDocRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
