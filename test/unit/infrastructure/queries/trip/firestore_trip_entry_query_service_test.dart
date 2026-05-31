import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/queries/trip/firestore_trip_entry_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_trip_entry_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  group('FirestoreTripEntryQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>>
    mockTripEntriesCollection;
    late MockCollectionReference<Map<String, dynamic>> mockTasksCollection;
    late MockCollectionReference<Map<String, dynamic>>
    mockItineraryItemsCollection;
    late FirestoreTripEntryQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTripEntriesCollection =
          MockCollectionReference<Map<String, dynamic>>();
      mockTasksCollection = MockCollectionReference<Map<String, dynamic>>();
      mockItineraryItemsCollection =
          MockCollectionReference<Map<String, dynamic>>();

      when(
        mockFirestore.collection('trip_entries'),
      ).thenReturn(mockTripEntriesCollection);
      when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
      when(
        mockFirestore.collection('itinerary_items'),
      ).thenReturn(mockItineraryItemsCollection);

      service = FirestoreTripEntryQueryService(firestore: mockFirestore);
    });

    test('旅行IDで旅行情報を取得し、tasksとitinerary_itemsも取得する', () async {
      const tripId = 'trip123';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockTaskDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockItineraryItemDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockTripEntriesCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(tripId);
      when(mockDocSnapshot.data()).thenReturn({
        'groupId': 'group001',
        'name': '夏旅行',
        'startDate': Timestamp.fromDate(DateTime(2024, 8, 1)),
        'endDate': Timestamp.fromDate(DateTime(2024, 8, 5)),
        'memo': '楽しかった思い出',
      });

      when(
        mockTasksCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockTasksQuery);
      when(
        mockTasksQuery.orderBy('orderIndex', descending: false),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([mockTaskDoc]);
      when(mockTaskDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 0,
        'name': '準備',
        'isCompleted': false,
      });
      when(mockTaskDoc.id).thenReturn('task001');

      when(
        mockItineraryItemsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.orderBy('startDateTime', descending: false),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.orderBy('endDateTime', descending: false),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([mockItineraryItemDoc]);
      when(mockItineraryItemDoc.data()).thenReturn({
        'tripId': tripId,
        'name': '朝食',
        'startDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 8)),
        'endDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 9)),
        'memo': 'ホテルで朝食',
      });
      when(mockItineraryItemDoc.id).thenReturn('item001');

      final result = await service.getTripEntryById(
        tripId,
        tasksOrderBy: const [OrderBy('orderIndex', descending: false)],
        itineraryItemsOrderBy: const [
          OrderBy('startDateTime', descending: false),
          OrderBy('endDateTime', descending: false),
        ],
      );

      expect(result, isNotNull);
      expect(result!.id, equals(tripId));
      expect(result.name, equals('夏旅行'));
      expect(result.tasks, hasLength(1));
      expect(result.tasks!.first.name, '準備');
      expect(result.itineraryItems, hasLength(1));
      final ItineraryItemDto itineraryItem = result.itineraryItems!.first;
      expect(itineraryItem.name, '朝食');
      verify(mockTasksQuery.orderBy('orderIndex', descending: false)).called(1);
      verify(
        mockItineraryItemsQuery.orderBy('startDateTime', descending: false),
      ).called(1);
      verify(
        mockItineraryItemsQuery.orderBy('endDateTime', descending: false),
      ).called(1);
      const removedCollection = 'pins';
      verifyNever(mockFirestore.collection(removedCollection));
    });

    test('旅行が存在しない場合はnullを返す', () async {
      const tripId = 'trip999';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockTripEntriesCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      final result = await service.getTripEntryById(tripId);

      expect(result, isNull);
    });

    test('yearと旅行期間が欠損している場合はクロックの年で補完する', () async {
      const tripId = 'tripWithoutYear';
      service = FirestoreTripEntryQueryService(
        firestore: mockFirestore,
        clock: FixedAppClock(DateTime.utc(2027, 1, 2)),
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(mockTripEntriesCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(tripId);
      when(
        mockDocSnapshot.data(),
      ).thenReturn({'groupId': 'group001', 'name': '期間未設定旅行'});
      when(
        mockTasksCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([]);
      when(
        mockItineraryItemsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.orderBy('startDateTime', descending: false),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.orderBy('endDateTime', descending: false),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([]);

      final result = await service.getTripEntryById(tripId);

      expect(result, isNotNull);
      expect(result!.year, 2027);
    });

    test('例外発生時はnullを返す', () async {
      when(mockTripEntriesCollection.doc(any)).thenThrow(TestException('取得失敗'));

      final result = await service.getTripEntryById('trip1');

      expect(result, isNull);
    });
  });
}
