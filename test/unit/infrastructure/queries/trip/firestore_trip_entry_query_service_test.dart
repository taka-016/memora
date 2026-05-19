import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
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
    late MockCollectionReference<Map<String, dynamic>> mockPinsCollection;
    late MockCollectionReference<Map<String, dynamic>> mockTasksCollection;
    late MockCollectionReference<Map<String, dynamic>>
    mockItineraryItemsCollection;
    late FirestoreTripEntryQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTripEntriesCollection =
          MockCollectionReference<Map<String, dynamic>>();
      mockPinsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockTasksCollection = MockCollectionReference<Map<String, dynamic>>();
      mockItineraryItemsCollection =
          MockCollectionReference<Map<String, dynamic>>();

      when(
        mockFirestore.collection('trip_entries'),
      ).thenReturn(mockTripEntriesCollection);
      when(mockFirestore.collection('pins')).thenReturn(mockPinsCollection);
      when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
      when(
        mockFirestore.collection('itinerary_items'),
      ).thenReturn(mockItineraryItemsCollection);

      service = FirestoreTripEntryQueryService(firestore: mockFirestore);
    });

    test('旅行IDで旅行情報を取得し、関連データを取得後に並び替える', () async {
      const tripId = 'trip123';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockPinsQuery = MockQuery<Map<String, dynamic>>();
      final mockPinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockPinDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockSecondPinDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockTasksQuery = MockQuery<Map<String, dynamic>>();
      final mockTasksSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockTaskDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockSecondTaskDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockItineraryItemsQuery = MockQuery<Map<String, dynamic>>();
      final mockItineraryItemsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockItineraryItemDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockSecondItineraryItemDoc =
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
        mockPinsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockPinsQuery);
      when(mockPinsQuery.get()).thenAnswer((_) async => mockPinsSnapshot);
      when(mockPinsSnapshot.docs).thenReturn([mockPinDoc, mockSecondPinDoc]);
      when(mockPinDoc.data()).thenReturn({
        'pinId': 'pin001',
        'tripId': tripId,
        'groupId': 'group001',
        'latitude': 35.0,
        'longitude': 139.0,
        'locationName': '東京タワー',
        'visitStartDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 10)),
        'visitEndDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 15)),
        'memo': '景色が綺麗',
      });
      when(mockSecondPinDoc.data()).thenReturn({
        'pinId': 'pin002',
        'tripId': tripId,
        'groupId': 'group001',
        'latitude': 34.0,
        'longitude': 135.0,
        'locationName': '京都駅',
        'visitStartDateTime': Timestamp.fromDate(DateTime(2024, 8, 1, 10)),
        'visitEndDateTime': Timestamp.fromDate(DateTime(2024, 8, 1, 15)),
        'memo': '集合',
      });

      when(
        mockTasksCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([
        mockTaskDoc,
        mockSecondTaskDoc,
      ]);
      when(mockTaskDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 2,
        'name': '荷造り',
        'isCompleted': false,
      });
      when(mockTaskDoc.id).thenReturn('task001');
      when(mockSecondTaskDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 1,
        'name': '予約確認',
        'isCompleted': false,
      });
      when(mockSecondTaskDoc.id).thenReturn('task002');

      when(
        mockItineraryItemsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([
        mockItineraryItemDoc,
        mockSecondItineraryItemDoc,
      ]);
      when(mockItineraryItemDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 3,
        'name': '夕食',
        'startDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 8)),
        'endDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 9)),
        'memo': 'ホテルで朝食',
      });
      when(mockItineraryItemDoc.id).thenReturn('item001');
      when(mockSecondItineraryItemDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 1,
        'name': '朝食',
        'startDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 8)),
        'endDateTime': Timestamp.fromDate(DateTime(2024, 8, 2, 9)),
        'memo': 'ホテルで朝食',
      });
      when(mockSecondItineraryItemDoc.id).thenReturn('item002');

      final result = await service.getTripEntryById(
        tripId,
        pinsOrderBy: const [OrderBy('visitStartDateTime', descending: false)],
        tasksOrderBy: const [OrderBy('orderIndex', descending: false)],
        itineraryItemsOrderBy: const [OrderBy('orderIndex', descending: false)],
      );

      expect(result, isNotNull);
      expect(result!.id, equals(tripId));
      expect(result.name, equals('夏旅行'));
      expect(result.pins, hasLength(2));
      final PinDto pin = result.pins!.first;
      expect(pin.locationName, equals('京都駅'));
      expect(result.tasks, hasLength(2));
      expect(result.tasks!.first.name, '予約確認');
      expect(result.itineraryItems, hasLength(2));
      final ItineraryItemDto itineraryItem = result.itineraryItems!.first;
      expect(itineraryItem.name, '朝食');
      verifyNever(mockPinsQuery.orderBy(any, descending: anyNamed('descending')));
      verifyNever(mockTasksQuery.orderBy(any, descending: anyNamed('descending')));
      verifyNever(
        mockItineraryItemsQuery.orderBy(any, descending: anyNamed('descending')),
      );
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
      final mockPinsQuery = MockQuery<Map<String, dynamic>>();
      final mockPinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
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
        mockPinsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockPinsQuery);
      when(mockPinsQuery.get()).thenAnswer((_) async => mockPinsSnapshot);
      when(mockPinsSnapshot.docs).thenReturn([]);
      when(
        mockTasksCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockTasksQuery);
      when(mockTasksQuery.get()).thenAnswer((_) async => mockTasksSnapshot);
      when(mockTasksSnapshot.docs).thenReturn([]);
      when(
        mockItineraryItemsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockItineraryItemsQuery);
      when(
        mockItineraryItemsQuery.get(),
      ).thenAnswer((_) async => mockItineraryItemsSnapshot);
      when(mockItineraryItemsSnapshot.docs).thenReturn([]);

      final result = await service.getTripEntryById(tripId);

      expect(result, isNotNull);
      expect(result!.year, 2027);
      verifyNever(
        mockItineraryItemsQuery.orderBy(any, descending: anyNamed('descending')),
      );
    });

    test('旅行取得時に例外が発生した場合はnullを返す', () async {
      when(
        mockTripEntriesCollection.doc(any),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getTripEntryById('trip001');

      expect(result, isNull);
    });

    test('グループIDとyearで旅行一覧を取得し、orderByを適用する', () async {
      const groupId = 'group001';
      const year = 2024;
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockTripEntriesCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.where('year', isEqualTo: year)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('startDate', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('trip001');
      when(mockDoc.data()).thenReturn({
        'groupId': groupId,
        'name': '冬旅行',
        'year': year,
        'startDate': Timestamp.fromDate(DateTime(2024, 12, 20)),
        'endDate': Timestamp.fromDate(DateTime(2024, 12, 25)),
        'memo': '温泉巡り',
      });

      final result = await service.getTripEntriesByGroupIdAndYear(
        groupId,
        year,
        orderBy: const [OrderBy('startDate', descending: false)],
      );

      expect(result, hasLength(1));
      verify(mockQuery.where('year', isEqualTo: year)).called(1);
      verify(mockQuery.orderBy('startDate', descending: false)).called(1);
    });

    test('グループIDと年での取得時に例外が発生すると空リストを返す', () async {
      when(
        mockTripEntriesCollection.where(
          'groupId',
          isEqualTo: anyNamed('isEqualTo'),
        ),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getTripEntriesByGroupIdAndYear(
        'group',
        2024,
      );

      expect(result, isEmpty);
    });
  });
}
