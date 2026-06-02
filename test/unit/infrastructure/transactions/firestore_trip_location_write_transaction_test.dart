import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/transactions/firestore_trip_location_write_transaction.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  Transaction,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
])
import 'firestore_trip_location_write_transaction_test.mocks.dart';

void main() {
  group('FirestoreTripLocationWriteTransaction', () {
    late MockFirebaseFirestore mockFirestore;
    late MockTransaction mockTransaction;
    late MockCollectionReference<Map<String, dynamic>> mockTripEntries;
    late MockCollectionReference<Map<String, dynamic>> mockItineraryItems;
    late MockCollectionReference<Map<String, dynamic>> mockTasks;
    late MockCollectionReference<Map<String, dynamic>> mockLocations;
    late FirestoreTripLocationWriteTransaction writeTransaction;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTransaction = MockTransaction();
      mockTripEntries = MockCollectionReference<Map<String, dynamic>>();
      mockItineraryItems = MockCollectionReference<Map<String, dynamic>>();
      mockTasks = MockCollectionReference<Map<String, dynamic>>();
      mockLocations = MockCollectionReference<Map<String, dynamic>>();

      when(mockFirestore.collection('trip_entries')).thenReturn(mockTripEntries);
      when(
        mockFirestore.collection('itinerary_items'),
      ).thenReturn(mockItineraryItems);
      when(mockFirestore.collection('tasks')).thenReturn(mockTasks);
      when(mockFirestore.collection('locations')).thenReturn(mockLocations);
      when(
        mockFirestore.runTransaction<String>(
          any,
          timeout: anyNamed('timeout'),
          maxAttempts: anyNamed('maxAttempts'),
        ),
      ).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments.first
                as Future<String> Function(Transaction);
        return handler(mockTransaction);
      });
      when(mockFirestore.runTransaction<void>(
        any,
        timeout: anyNamed('timeout'),
        maxAttempts: anyNamed('maxAttempts'),
      )).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments.first
                as Future<void> Function(Transaction);
        await handler(mockTransaction);
      });

      writeTransaction = FirestoreTripLocationWriteTransaction(
        firestore: mockFirestore,
      );
    });

    test('旅行作成とlocation保存を同じFirestore transactionで実行する', () async {
      final tripEntry = TripEntry(
        id: '',
        groupId: 'group-1',
        year: 2024,
        itineraryItems: [
          ItineraryItem(
            id: 'item-1',
            tripId: '',
            name: '朝食',
            locationId: 'location-1',
          ),
        ],
      );
      final location = Location(
        id: 'location-1',
        tripId: '',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockLocationDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockTripDocRef.id).thenReturn('generated-trip-id');
      when(mockTripEntries.doc()).thenReturn(mockTripDocRef);
      when(mockItineraryItems.doc('item-1')).thenReturn(mockItineraryItemDocRef);
      when(mockLocations.doc('location-1')).thenReturn(mockLocationDocRef);

      final result = await writeTransaction.run((operations) async {
        final tripId = await operations.saveTripEntry(tripEntry);
        await operations.saveLocation(location.copyWith(tripId: tripId));
        return tripId;
      });

      expect(result, 'generated-trip-id');
      verify(mockFirestore.runTransaction<String>(any)).called(1);
      verify(mockTransaction.set(mockTripDocRef, any)).called(1);
      verify(mockTransaction.set(mockItineraryItemDocRef, any)).called(1);
      verify(
        mockTransaction.set(
          mockLocationDocRef,
          argThat(
            allOf([
              containsPair('tripId', 'generated-trip-id'),
              containsPair('name', '東京駅'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('旅行更新とlocation差分を同じFirestore transactionで実行する', () async {
      final tripEntry = TripEntry(
        id: 'trip-1',
        groupId: 'group-1',
        year: 2024,
        itineraryItems: [
          ItineraryItem(
            id: 'item-1',
            tripId: 'trip-1',
            name: '朝食',
            locationId: 'location-1',
          ),
        ],
      );
      final location = Location(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      final mockTripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockItineraryItemDocRef =
          MockDocumentReference<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockLocationDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDeletedLocationDocRef =
          MockDocumentReference<Map<String, dynamic>>();

      when(mockTripEntries.doc('trip-1')).thenReturn(mockTripDocRef);
      when(mockTasks.where('tripId', isEqualTo: 'trip-1'))
          .thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([]);
      when(mockItineraryItems.where('tripId', isEqualTo: 'trip-1'))
          .thenReturn(mockItineraryItemsQuery);
      when(mockItineraryItemsQuery.get())
          .thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([]);
      when(mockItineraryItems.doc('item-1')).thenReturn(mockItineraryItemDocRef);
      when(mockLocations.doc('location-1')).thenReturn(mockLocationDocRef);
      when(
        mockLocations.doc('location-old'),
      ).thenReturn(mockDeletedLocationDocRef);

      await writeTransaction.run<void>((operations) async {
        await operations.updateTripEntry(tripEntry);
        await operations.saveLocation(location);
        await operations.deleteLocation('location-old');
      });

      verify(mockFirestore.runTransaction<void>(any)).called(1);
      verify(mockTransaction.update(mockTripDocRef, any)).called(1);
      verify(mockTransaction.set(mockItineraryItemDocRef, any)).called(1);
      verify(
        mockTransaction.set(
          mockLocationDocRef,
          argThat(
            allOf([
              containsPair('tripId', 'trip-1'),
              containsPair('name', '東京駅'),
              isNot(contains('createdAt')),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verify(mockTransaction.delete(mockDeletedLocationDocRef)).called(1);
    });
  });
}
