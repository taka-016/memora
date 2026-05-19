import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
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
    late MockCollectionReference<Map<String, dynamic>> mockTasksCollection;
    late MockCollectionReference<Map<String, dynamic>>
    mockItineraryItemsCollection;
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
      mockTasksCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
      mockItineraryItemsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('itinerary_items'),
      ).thenReturn(mockItineraryItemsCollection);
      repository = FirestoreTripEntryRepository(firestore: mockFirestore);
    });

    test(
      'saveTripEntryがtrip_entries collectionに旅行情報をaddし、ドキュメントIDを返す',
      () async {
        final tripEntry = TripEntry(
          id: 'trip001',
          groupId: 'group001',
          year: 2025,
          name: 'テスト旅行',
          startDate: DateTime(2025, 6, 1),
          endDate: DateTime(2025, 6, 10),
          memo: 'テストメモ',
          tasks: [
            Task(
              id: 'task-001',
              tripId: 'trip001',
              orderIndex: 0,
              name: '準備',
              isCompleted: false,
            ),
          ],
          itineraryItems: [
            ItineraryItem(id: 'item-001', tripId: 'trip001', name: '朝食'),
          ],
        );

        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockBatch = MockWriteBatch();
        final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockItineraryItemDocRef =
            MockDocumentReference<Map<String, dynamic>>();
        when(mockDocRef.id).thenReturn('generated-doc-id');
        when(mockCollection.doc()).thenReturn(mockDocRef);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});
        when(mockTasksCollection.doc('task-001')).thenReturn(mockTaskDocRef);
        when(
          mockItineraryItemsCollection.doc('item-001'),
        ).thenReturn(mockItineraryItemDocRef);

        final result = await repository.saveTripEntry(tripEntry);

        expect(result, equals('generated-doc-id'));
        verify(mockFirestore.batch()).called(1);
        verify(mockCollection.doc()).called(1);
        verify(
          mockBatch.set(
            mockDocRef,
            argThat(
              allOf([
                containsPair('groupId', 'group001'),
                containsPair('year', 2025),
                containsPair('name', 'テスト旅行'),
                isNot(contains('tripYear')),
                isNot(contains('tripName')),
                contains('createdAt'),
                contains('updatedAt'),
              ]),
            ),
          ),
        ).called(1);
        verify(mockTasksCollection.doc('task-001')).called(1);
        verify(mockBatch.set(mockTaskDocRef, any)).called(1);
        verify(mockItineraryItemsCollection.doc('item-001')).called(1);
        verify(
          mockBatch.set(
            mockItineraryItemDocRef,
            argThat(
              allOf([
                containsPair('tripId', 'generated-doc-id'),
                containsPair('name', '朝食'),
                contains('createdAt'),
                contains('updatedAt'),
              ]),
            ),
          ),
        ).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );

    test('updateTripEntryが既存の子エンティティを削除して再作成する', () async {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        year: 2025,
        tasks: [
          Task(
            id: 'task-uuid',
            tripId: 'trip001',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
        itineraryItems: [
          ItineraryItem(id: 'item-uuid', tripId: 'trip001', name: '朝食'),
        ],
      );

      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();
      final mockPinsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockPinsQuery = MockQuery<Map<String, dynamic>>();
      final mockPinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockExistingTaskDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockExistingTaskDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockTaskDocRefWithId =
          MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockExistingItineraryItemDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockExistingItineraryItemDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemDocRefWithId =
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
        mockTasksCollection.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([mockExistingTaskDoc]);
      when(mockExistingTaskDoc.id).thenReturn('task-uuid');
      when(mockExistingTaskDoc.reference).thenReturn(mockExistingTaskDocRef);
      when(
        mockTasksCollection.doc('task-uuid'),
      ).thenReturn(mockTaskDocRefWithId);
      when(
        mockItineraryItemsCollection.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(
        mockItineraryItemsSnapshot.docs,
      ).thenReturn([mockExistingItineraryItemDoc]);
      when(
        mockExistingItineraryItemDoc.reference,
      ).thenReturn(mockExistingItineraryItemDocRef);
      when(
        mockItineraryItemsCollection.doc('item-uuid'),
      ).thenReturn(mockItineraryItemDocRefWithId);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.updateTripEntry(tripEntry);

      verify(
        mockBatch.update(
          mockTripDocRef,
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('year', 2025),
              isNot(contains('tripYear')),
              contains('updatedAt'),
              predicate<Map<String, dynamic>>(
                (data) => !data.containsKey('createdAt'),
                'createdAtを含まない',
              ),
            ]),
          ),
        ),
      ).called(1);
      verify(mockBatch.delete(mockExistingTaskDocRef)).called(1);
      verify(mockBatch.delete(mockExistingItineraryItemDocRef)).called(1);
      verify(mockTasksCollection.doc('task-uuid')).called(1);
      verify(
        mockBatch.set(
          mockTaskDocRefWithId,
          argThat(
            allOf([
              containsPair('tripId', 'trip001'),
              containsPair('name', '準備'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verify(mockItineraryItemsCollection.doc('item-uuid')).called(1);
      verify(
        mockBatch.set(
          mockItineraryItemDocRefWithId,
          argThat(
            allOf([
              containsPair('tripId', 'trip001'),
              containsPair('name', '朝食'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
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
        final mockTasksCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockTasksQuery = MockQuery<Map<String, dynamic>>();
        final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockTaskDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockItineraryItemsCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
        final mockItineraryItemsSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockItineraryItemDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockItineraryItemDocRef =
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

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(
          mockTasksCollection.where('tripId', isEqualTo: tripId),
        ).thenReturn(mockTasksQuery);
        when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
        when(mockTasksSnapshot.docs).thenReturn([mockTaskDoc]);
        when(mockTaskDoc.reference).thenReturn(mockTaskDocRef);

        when(
          mockFirestore.collection('itinerary_items'),
        ).thenReturn(mockItineraryItemsCollection);
        when(
          mockItineraryItemsCollection.where('tripId', isEqualTo: tripId),
        ).thenReturn(mockItineraryItemsQuery);
        when(
          mockItineraryItemsQuery.get(),
        ).thenAnswer((_) async => mockItineraryItemsSnapshot);
        when(
          mockItineraryItemsSnapshot.docs,
        ).thenReturn([mockItineraryItemDoc]);
        when(
          mockItineraryItemDoc.reference,
        ).thenReturn(mockItineraryItemDocRef);

        when(mockBatch.commit()).thenAnswer((_) async {});

        await repository.deleteTripEntry(tripId);

        verify(mockCollection.doc(tripId)).called(1);
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(mockPinDocRef)).called(1);
        verify(mockBatch.delete(mockDocRef)).called(1);
        verify(mockBatch.delete(mockTaskDocRef)).called(1);
        verify(mockBatch.delete(mockItineraryItemDocRef)).called(1);
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
        final mockTasksCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockTasksQuery1 = MockQuery<Map<String, dynamic>>();
        final mockTasksSnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockTaskDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockTaskDocRef1 = MockDocumentReference<Map<String, dynamic>>();
        final mockTasksQuery2 = MockQuery<Map<String, dynamic>>();
        final mockTasksSnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockItineraryItemsCollection =
            MockCollectionReference<Map<String, dynamic>>();
        final mockItineraryItemsQuery1 = MockQuery<Map<String, dynamic>>();
        final mockItineraryItemsSnapshot1 =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockItineraryItemDoc1 =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockItineraryItemDocRef1 =
            MockDocumentReference<Map<String, dynamic>>();
        final mockItineraryItemsQuery2 = MockQuery<Map<String, dynamic>>();
        final mockItineraryItemsSnapshot2 =
            MockQuerySnapshot<Map<String, dynamic>>();

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

        when(
          mockFirestore.collection('itinerary_items'),
        ).thenReturn(mockItineraryItemsCollection);
        when(
          mockItineraryItemsCollection.where('tripId', isEqualTo: 'trip001'),
        ).thenReturn(mockItineraryItemsQuery1);
        when(
          mockItineraryItemsQuery1.get(),
        ).thenAnswer((_) async => mockItineraryItemsSnapshot1);
        when(
          mockItineraryItemsSnapshot1.docs,
        ).thenReturn([mockItineraryItemDoc1]);
        when(
          mockItineraryItemDoc1.reference,
        ).thenReturn(mockItineraryItemDocRef1);

        when(
          mockItineraryItemsCollection.where('tripId', isEqualTo: 'trip002'),
        ).thenReturn(mockItineraryItemsQuery2);
        when(
          mockItineraryItemsQuery2.get(),
        ).thenAnswer((_) async => mockItineraryItemsSnapshot2);
        when(mockItineraryItemsSnapshot2.docs).thenReturn([]);

        when(mockBatch.commit()).thenAnswer((_) async {});

        await repository.deleteTripEntriesByGroupId(groupId);

        verify(mockCollection.where('groupId', isEqualTo: groupId)).called(1);
        verify(mockQuery.get()).called(1);
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(mockPinDocRef1)).called(1);
        verify(mockBatch.delete(mockDocRef1)).called(1);
        verify(mockBatch.delete(mockDocRef2)).called(1);
        verify(mockBatch.delete(mockTaskDocRef1)).called(1);
        verify(mockBatch.delete(mockItineraryItemDocRef1)).called(1);
        verify(mockBatch.commit()).called(1);
      },
    );
  });
}
