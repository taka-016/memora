import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';

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
    late MockCollectionReference<Map<String, dynamic>> mockRoutesCollection;
    late MockCollectionReference<Map<String, dynamic>> mockTasksCollection;
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
      mockRoutesCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('trip_entries')).thenReturn(mockCollection);
      when(mockFirestore.collection('routes')).thenReturn(mockRoutesCollection);
      mockTasksCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
      repository = FirestoreTripEntryRepository(firestore: mockFirestore);
    });

    test(
      'saveTripEntryがtrip_entries collectionに旅行情報をaddし、ドキュメントIDを返す',
      () async {
        final tripEntry = TripEntry(
          id: 'trip001',
          groupId: 'group001',
          tripYear: 2025,
          tripName: 'テスト旅行',
          tripStartDate: DateTime(2025, 6, 1),
          tripEndDate: DateTime(2025, 6, 10),
          tripMemo: 'テストメモ',
          routes: [
            Route(
              tripId: 'trip001',
              orderIndex: 0,
              departurePinId: 'pin001',
              arrivalPinId: 'pin002',
              travelMode: TravelMode.drive,
            ),
          ],
          tasks: [
            Task(
              id: 'task-001',
              tripId: 'trip001',
              orderIndex: 0,
              name: '準備',
              isCompleted: false,
            ),
          ],
        );

        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockBatch = MockWriteBatch();
        final mockRouteDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockDocRef.id).thenReturn('generated-doc-id');
        when(mockCollection.doc()).thenReturn(mockDocRef);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});
        when(mockRoutesCollection.doc()).thenReturn(mockRouteDocRef);
        when(mockTasksCollection.doc('task-001')).thenReturn(mockTaskDocRef);

        final result = await repository.saveTripEntry(tripEntry);

        expect(result, equals('generated-doc-id'));
        verify(mockFirestore.batch()).called(1);
        verify(mockCollection.doc()).called(1);
        verify(mockRoutesCollection.doc()).called(1);
        verify(mockBatch.set(mockRouteDocRef, any)).called(1);
        verify(mockTasksCollection.doc('task-001')).called(1);
        verify(mockBatch.set(mockTaskDocRef, any)).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );

    test('updateTripEntryが既存タスクのidを保持したまま更新する', () async {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        tripYear: 2025,
        tasks: [
          Task(
            id: 'task-uuid',
            tripId: 'trip001',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
      );

      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();
      final mockPinsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockPinsQuery = MockQuery<Map<String, dynamic>>();
      final mockPinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockRoutesQuery = MockQuery<Map<String, dynamic>>();
      final mockRoutesSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockTaskDocRefWithId =
          MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc('trip001')).thenReturn(mockTripDocRef);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockFirestore.collection('pins')).thenReturn(mockPinsCollection);
      when(
        mockPinsCollection.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockPinsQuery);
      when(mockPinsQuery.get()).thenAnswer((_) async => mockPinsSnapshot);
      when(mockPinsSnapshot.docs).thenReturn([]);

      when(
        mockRoutesCollection.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockRoutesQuery);
      when(mockRoutesQuery.get()).thenAnswer((_) async => mockRoutesSnapshot);
      when(mockRoutesSnapshot.docs).thenReturn([]);

      when(
        mockTasksCollection.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([]);

      when(
        mockTasksCollection.doc('task-uuid'),
      ).thenReturn(mockTaskDocRefWithId);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.updateTripEntry(tripEntry);

      verify(mockTasksCollection.doc('task-uuid')).called(1);
    });

    test(
      'deleteTripEntryがtrip_entries collectionの該当ドキュメントとpinsを削除する',
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
        final mockRoutesQuery = MockQuery<Map<String, dynamic>>();
        final mockRoutesSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockRouteDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockRouteDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockTasksCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockTasksQuery = MockQuery<Map<String, dynamic>>();
        final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockTaskDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();

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
          mockRoutesCollection.where('tripId', isEqualTo: tripId),
        ).thenReturn(mockRoutesQuery);
        when(mockRoutesQuery.get()).thenAnswer((_) async => mockRoutesSnapshot);
        when(mockRoutesSnapshot.docs).thenReturn([mockRouteDoc]);
        when(mockRouteDoc.reference).thenReturn(mockRouteDocRef);

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(
          mockTasksCollection.where('tripId', isEqualTo: tripId),
        ).thenReturn(mockTasksQuery);
        when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
        when(mockTasksSnapshot.docs).thenReturn([mockTaskDoc]);
        when(mockTaskDoc.reference).thenReturn(mockTaskDocRef);

        when(mockBatch.commit()).thenAnswer((_) async {});

        await repository.deleteTripEntry(tripId);

        verify(mockCollection.doc(tripId)).called(1);
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(mockPinDocRef)).called(1);
        verify(mockBatch.delete(mockDocRef)).called(1);
        verify(mockBatch.delete(mockRouteDocRef)).called(1);
        verify(mockBatch.delete(mockTaskDocRef)).called(1);
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
        final mockRoutesQuery1 = MockQuery<Map<String, dynamic>>();
        final mockRoutesSnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockRouteDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockRouteDocRef1 = MockDocumentReference<Map<String, dynamic>>();
        final mockRoutesQuery2 = MockQuery<Map<String, dynamic>>();
        final mockRoutesSnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockTasksCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockTasksQuery1 = MockQuery<Map<String, dynamic>>();
        final mockTasksSnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockTaskDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockTaskDocRef1 = MockDocumentReference<Map<String, dynamic>>();
        final mockTasksQuery2 = MockQuery<Map<String, dynamic>>();
        final mockTasksSnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();

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

        when(
          mockRoutesCollection.where('tripId', isEqualTo: 'trip001'),
        ).thenReturn(mockRoutesQuery1);
        when(
          mockRoutesQuery1.get(),
        ).thenAnswer((_) async => mockRoutesSnapshot1);
        when(mockRoutesSnapshot1.docs).thenReturn([mockRouteDoc1]);
        when(mockRouteDoc1.reference).thenReturn(mockRouteDocRef1);

        when(
          mockRoutesCollection.where('tripId', isEqualTo: 'trip002'),
        ).thenReturn(mockRoutesQuery2);
        when(
          mockRoutesQuery2.get(),
        ).thenAnswer((_) async => mockRoutesSnapshot2);
        when(mockRoutesSnapshot2.docs).thenReturn([]);

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(
          mockTasksCollection.where('tripId', isEqualTo: 'trip001'),
        ).thenReturn(mockTasksQuery1);
        when(mockTasksQuery1.get()).thenAnswer((_) async => mockTasksSnapshot1);
        when(mockTasksSnapshot1.docs).thenReturn([mockTaskDoc1]);
        when(mockTaskDoc1.reference).thenReturn(mockTaskDocRef1);

        when(
          mockTasksCollection.where('tripId', isEqualTo: 'trip002'),
        ).thenReturn(mockTasksQuery2);
        when(mockTasksQuery2.get()).thenAnswer((_) async => mockTasksSnapshot2);
        when(mockTasksSnapshot2.docs).thenReturn([]);

        when(mockBatch.commit()).thenAnswer((_) async {});

        await repository.deleteTripEntriesByGroupId(groupId);

        verify(mockCollection.where('groupId', isEqualTo: groupId)).called(1);
        verify(mockQuery.get()).called(1);
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(mockPinDocRef1)).called(1);
        verify(mockBatch.delete(mockDocRef1)).called(1);
        verify(mockBatch.delete(mockDocRef2)).called(1);
        verify(mockBatch.delete(mockRouteDocRef1)).called(1);
        verify(mockBatch.delete(mockTaskDocRef1)).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );
  });
}
