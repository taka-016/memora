import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_entry_repository.dart';
import 'package:memora/domain/entities/trip_entry.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
  WriteBatch,
])
import 'firestore_trip_entry_repository_test.mocks.dart';

void main() {
  group('FirestoreTripEntryRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreTripEntryRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc2;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('trip_entries')).thenReturn(mockCollection);
      repository = FirestoreTripEntryRepository(firestore: mockFirestore);
    });

    test(
      'saveTripEntryがtrip_entries collectionに旅行情報をaddし、ドキュメントIDを返す',
      () async {
        final tripEntry = TripEntry(
          id: 'trip001',
          groupId: 'group001',
          tripName: 'テスト旅行',
          tripStartDate: DateTime(2025, 6, 1),
          tripEndDate: DateTime(2025, 6, 10),
          tripMemo: 'テストメモ',
        );

        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockBatch = MockWriteBatch();
        when(mockDocRef.id).thenReturn('generated-doc-id');
        when(mockCollection.doc()).thenReturn(mockDocRef);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        final result = await repository.saveTripEntry(tripEntry);

        expect(result, equals('generated-doc-id'));
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );

    test(
      'deleteTripEntryがtrip_entries collectionの該当ドキュメントとpinsとpin_detailsを削除する',
      () async {
        const tripId = 'trip001';
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockBatch = MockWriteBatch();
        final mockPinsCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockPinsQuery = MockQuery<Map<String, dynamic>>();
        final mockPinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockPinDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockPinDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockPinDetailsCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockPinDetailsQuery = MockQuery<Map<String, dynamic>>();
        final mockPinDetailsSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockPinDetailDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockPinDetailDocRef =
            MockDocumentReference<Map<String, dynamic>>();

        when(mockCollection.doc(tripId)).thenReturn(mockDocRef);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockFirestore.collection('pins')).thenReturn(mockPinsCollection);
        when(
          mockPinsCollection.where('tripId', isEqualTo: tripId),
        ).thenReturn(mockPinsQuery);
        when(mockPinsQuery.get()).thenAnswer((_) async => mockPinsSnapshot);
        when(mockPinsSnapshot.docs).thenReturn([mockPinDoc]);
        when(mockPinDoc.data()).thenReturn({'pinId': 'pin001'});
        when(mockPinDoc.reference).thenReturn(mockPinDocRef);

        when(
          mockFirestore.collection('pin_details'),
        ).thenReturn(mockPinDetailsCollection);
        when(
          mockPinDetailsCollection.where('pinId', isEqualTo: 'pin001'),
        ).thenReturn(mockPinDetailsQuery);
        when(
          mockPinDetailsQuery.get(),
        ).thenAnswer((_) async => mockPinDetailsSnapshot);
        when(mockPinDetailsSnapshot.docs).thenReturn([mockPinDetailDoc]);
        when(mockPinDetailDoc.reference).thenReturn(mockPinDetailDocRef);

        when(mockBatch.commit()).thenAnswer((_) async {});

        await repository.deleteTripEntry(tripId);

        verify(mockCollection.doc(tripId)).called(1);
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(mockPinDetailDocRef)).called(1);
        verify(mockBatch.delete(mockPinDocRef)).called(1);
        verify(mockBatch.delete(mockDocRef)).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );

    test(
      'deleteTripEntriesByGroupIdが指定したgroupIdの全旅行エントリとその子エンティティを削除する',
      () async {
        const groupId = 'group001';
        final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
        final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();
        final mockBatch = MockWriteBatch();
        final mockPinsCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockPinsQuery1 = MockQuery<Map<String, dynamic>>();
        final mockPinsQuery2 = MockQuery<Map<String, dynamic>>();
        final mockPinsSnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockPinsSnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockPinDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockPinDocRef1 = MockDocumentReference<Map<String, dynamic>>();
        final mockPinDetailsCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockPinDetailsQuery = MockQuery<Map<String, dynamic>>();
        final mockPinDetailsSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockPinDetailDoc1 =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockPinDetailDocRef1 =
            MockDocumentReference<Map<String, dynamic>>();

        when(
          mockCollection.where('groupId', isEqualTo: groupId),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
        when(mockDoc1.id).thenReturn('trip001');
        when(mockDoc2.id).thenReturn('trip002');
        when(mockDoc1.reference).thenReturn(mockDocRef1);
        when(mockDoc2.reference).thenReturn(mockDocRef2);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockFirestore.collection('pins')).thenReturn(mockPinsCollection);

        // trip001のpins
        when(
          mockPinsCollection.where('tripId', isEqualTo: 'trip001'),
        ).thenReturn(mockPinsQuery1);
        when(mockPinsQuery1.get()).thenAnswer((_) async => mockPinsSnapshot1);
        when(mockPinsSnapshot1.docs).thenReturn([mockPinDoc1]);
        when(mockPinDoc1.data()).thenReturn({'pinId': 'pin001'});
        when(mockPinDoc1.reference).thenReturn(mockPinDocRef1);

        // trip002のpins（なし）
        when(
          mockPinsCollection.where('tripId', isEqualTo: 'trip002'),
        ).thenReturn(mockPinsQuery2);
        when(mockPinsQuery2.get()).thenAnswer((_) async => mockPinsSnapshot2);
        when(mockPinsSnapshot2.docs).thenReturn([]);

        // pin001のpin_details
        when(
          mockFirestore.collection('pin_details'),
        ).thenReturn(mockPinDetailsCollection);
        when(
          mockPinDetailsCollection.where('pinId', isEqualTo: 'pin001'),
        ).thenReturn(mockPinDetailsQuery);
        when(
          mockPinDetailsQuery.get(),
        ).thenAnswer((_) async => mockPinDetailsSnapshot);
        when(mockPinDetailsSnapshot.docs).thenReturn([mockPinDetailDoc1]);
        when(mockPinDetailDoc1.reference).thenReturn(mockPinDetailDocRef1);

        when(mockBatch.commit()).thenAnswer((_) async {});

        await repository.deleteTripEntriesByGroupId(groupId);

        verify(mockCollection.where('groupId', isEqualTo: groupId)).called(1);
        verify(mockQuery.get()).called(1);
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(mockPinDetailDocRef1)).called(1);
        verify(mockBatch.delete(mockPinDocRef1)).called(1);
        verify(mockBatch.delete(mockDocRef1)).called(1);
        verify(mockBatch.delete(mockDocRef2)).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );
  });
}
