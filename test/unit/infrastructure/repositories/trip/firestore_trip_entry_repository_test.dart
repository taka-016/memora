import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  WriteBatch,
])
import 'firestore_trip_entry_repository_test.mocks.dart';

void main() {
  group('FirestoreTripEntryRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockTripEntries;
    late MockCollectionReference<Map<String, dynamic>> mockLocations;
    late MockCollectionReference<Map<String, dynamic>> mockTasks;
    late MockCollectionReference<Map<String, dynamic>> mockItineraryItems;
    late FirestoreTripEntryRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTripEntries = MockCollectionReference<Map<String, dynamic>>();
      mockLocations = MockCollectionReference<Map<String, dynamic>>();
      mockTasks = MockCollectionReference<Map<String, dynamic>>();
      mockItineraryItems = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('trip_entries'),
      ).thenReturn(mockTripEntries);
      when(mockFirestore.collection('locations')).thenReturn(mockLocations);
      when(mockFirestore.collection('tasks')).thenReturn(mockTasks);
      when(
        mockFirestore.collection('itinerary_items'),
      ).thenReturn(mockItineraryItems);
      repository = FirestoreTripEntryRepository(firestore: mockFirestore);
    });

    test('saveTripEntryが旅行と子要素を保存する', () async {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        year: 2025,
        name: 'テスト旅行',
        locations: [
          Location(
            id: 'location-001',
            tripId: 'trip001',
            groupId: 'group001',
            name: '東京駅',
            latitude: 35.681236,
            longitude: 139.767125,
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
        itineraryItems: [
          ItineraryItem(id: 'item-001', tripId: 'trip001', name: '朝食'),
        ],
      );

      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockLocationDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();
      when(mockTripDocRef.id).thenReturn('generated-trip-id');
      when(mockTripEntries.doc()).thenReturn(mockTripDocRef);
      when(mockLocations.doc('location-001')).thenReturn(mockLocationDocRef);
      when(mockTasks.doc('task-001')).thenReturn(mockTaskDocRef);
      when(
        mockItineraryItems.doc('item-001'),
      ).thenReturn(mockItineraryItemDocRef);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async {});

      final result = await repository.saveTripEntry(tripEntry);

      expect(result, 'generated-trip-id');
      verify(mockBatch.set(mockTripDocRef, any)).called(1);
      verify(
        mockBatch.set(
          mockLocationDocRef,
          argThat(containsPair('tripId', 'generated-trip-id')),
        ),
      ).called(1);
      verify(mockBatch.set(mockTaskDocRef, any)).called(1);
      verify(mockBatch.set(mockItineraryItemDocRef, any)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('updateTripEntryが既存のlocations、tasks、itinerary_itemsを同期する', () async {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        year: 2025,
        locations: [
          Location(
            id: 'location-001',
            tripId: 'trip001',
            groupId: 'group001',
            name: '東京駅',
            latitude: 35.681236,
            longitude: 139.767125,
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
        itineraryItems: [
          ItineraryItem(id: 'item-001', tripId: 'trip001', name: '朝食'),
        ],
      );
      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockLocationDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockLocationsQuery = MockQuery<Map<String, dynamic>>();
      final mockLocationsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockExistingLocationDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockExistingLocationDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      when(mockTripEntries.doc('trip001')).thenReturn(mockTripDocRef);
      when(
        mockLocations.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockLocationsQuery);
      when(
        mockLocationsQuery.get(),
      ).thenAnswer((_) async => mockLocationsSnapshot);
      when(mockLocationsSnapshot.docs).thenReturn([mockExistingLocationDoc]);
      when(
        mockExistingLocationDoc.reference,
      ).thenReturn(mockExistingLocationDocRef);
      when(
        mockTasks.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([]);
      when(
        mockItineraryItems.where('tripId', isEqualTo: 'trip001'),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([]);
      when(mockTasks.doc('task-001')).thenReturn(mockTaskDocRef);
      when(mockLocations.doc('location-001')).thenReturn(mockLocationDocRef);
      when(
        mockItineraryItems.doc('item-001'),
      ).thenReturn(mockItineraryItemDocRef);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.updateTripEntry(tripEntry);

      verify(mockBatch.update(mockTripDocRef, any)).called(1);
      verify(mockBatch.delete(mockExistingLocationDocRef)).called(1);
      verify(mockBatch.set(mockLocationDocRef, any)).called(1);
      verify(mockBatch.set(mockTaskDocRef, any)).called(1);
      verify(mockBatch.set(mockItineraryItemDocRef, any)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('deleteTripEntryが旅行と子要素を削除する', () async {
      const tripId = 'trip001';
      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockLocationsQuery = MockQuery<Map<String, dynamic>>();
      final mockLocationsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockLocationDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockLocationDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockTaskDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockTaskDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockItineraryItemDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockItineraryItemDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      when(mockTripEntries.doc(tripId)).thenReturn(mockTripDocRef);
      when(
        mockLocations.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockLocationsQuery);
      when(
        mockLocationsQuery.get(),
      ).thenAnswer((_) async => mockLocationsSnapshot);
      when(mockLocationsSnapshot.docs).thenReturn([mockLocationDoc]);
      when(mockLocationDoc.reference).thenReturn(mockLocationDocRef);
      when(
        mockTasks.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([mockTaskDoc]);
      when(mockTaskDoc.reference).thenReturn(mockTaskDocRef);
      when(
        mockItineraryItems.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([mockItineraryItemDoc]);
      when(mockItineraryItemDoc.reference).thenReturn(mockItineraryItemDocRef);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteTripEntry(tripId);

      verify(mockBatch.delete(mockLocationDocRef)).called(1);
      verify(mockBatch.delete(mockTaskDocRef)).called(1);
      verify(mockBatch.delete(mockItineraryItemDocRef)).called(1);
      verify(mockBatch.delete(mockTripDocRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
