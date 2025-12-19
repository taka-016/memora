import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_detail_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
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
    late MockCollectionReference<Map<String, dynamic>> mockPinDetailsCollection;
    late MockCollectionReference<Map<String, dynamic>> mockRoutesCollection;
    late FirestoreTripEntryQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTripEntriesCollection =
          MockCollectionReference<Map<String, dynamic>>();
      mockPinsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockPinDetailsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      mockRoutesCollection = MockCollectionReference<Map<String, dynamic>>();

      when(
        mockFirestore.collection('trip_entries'),
      ).thenReturn(mockTripEntriesCollection);
      when(mockFirestore.collection('pins')).thenReturn(mockPinsCollection);
      when(
        mockFirestore.collection('pin_details'),
      ).thenReturn(mockPinDetailsCollection);
      when(mockFirestore.collection('routes')).thenReturn(mockRoutesCollection);

      service = FirestoreTripEntryQueryService(firestore: mockFirestore);
    });

    test('旅行IDで旅行情報を取得し、関連するピンと詳細も取得する', () async {
      const tripId = 'trip123';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockPinsQuery = MockQuery<Map<String, dynamic>>();
      final mockPinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockPinDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockPinDetailsQuery = MockQuery<Map<String, dynamic>>();
      final mockPinDetailsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockPinDetailDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockRoutesQuery = MockQuery<Map<String, dynamic>>();
      final mockRoutesSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockRouteDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockTripEntriesCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(tripId);
      when(mockDocSnapshot.data()).thenReturn({
        'groupId': 'group001',
        'tripName': '夏旅行',
        'tripStartDate': Timestamp.fromDate(DateTime(2024, 8, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2024, 8, 5)),
        'tripMemo': '楽しかった思い出',
      });

      when(
        mockPinsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockPinsQuery);
      when(
        mockPinsQuery.orderBy('visitStartDate', descending: false),
      ).thenReturn(mockPinsQuery);
      when(mockPinsQuery.get()).thenAnswer((_) async => mockPinsSnapshot);
      when(mockPinsSnapshot.docs).thenReturn([mockPinDoc]);
      when(mockPinDoc.data()).thenReturn({
        'pinId': 'pin001',
        'tripId': tripId,
        'groupId': 'group001',
        'latitude': 35.0,
        'longitude': 139.0,
        'locationName': '東京タワー',
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 8, 2, 10)),
        'visitEndDate': Timestamp.fromDate(DateTime(2024, 8, 2, 15)),
        'visitMemo': '景色が綺麗',
      });

      when(
        mockPinDetailsCollection.where('pinId', isEqualTo: 'pin001'),
      ).thenReturn(mockPinDetailsQuery);
      when(
        mockPinDetailsQuery.orderBy('startDate', descending: false),
      ).thenReturn(mockPinDetailsQuery);
      when(
        mockPinDetailsQuery.get(),
      ).thenAnswer((_) async => mockPinDetailsSnapshot);
      when(mockPinDetailsSnapshot.docs).thenReturn([mockPinDetailDoc]);
      when(mockPinDetailDoc.data()).thenReturn({
        'pinId': 'pin001',
        'name': 'ランチ',
        'startDate': Timestamp.fromDate(DateTime(2024, 8, 2, 12)),
        'endDate': Timestamp.fromDate(DateTime(2024, 8, 2, 13)),
        'memo': '近くのカフェ',
      });

      when(
        mockRoutesCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockRoutesQuery);
      when(
        mockRoutesQuery.orderBy('orderIndex', descending: false),
      ).thenReturn(mockRoutesQuery);
      when(mockRoutesQuery.get()).thenAnswer((_) async => mockRoutesSnapshot);
      when(mockRoutesSnapshot.docs).thenReturn([mockRouteDoc]);
      when(mockRouteDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 0,
        'departurePinId': 'pin001',
        'arrivalPinId': 'pin002',
        'travelMode': 'DRIVE',
      });
      when(mockRouteDoc.id).thenReturn('route001');

      final result = await service.getTripEntryById(
        tripId,
        pinsOrderBy: const [OrderBy('visitStartDate', descending: false)],
        pinDetailsOrderBy: const [OrderBy('startDate', descending: false)],
        routesOrderBy: const [OrderBy('orderIndex', descending: false)],
      );

      expect(result, isNotNull);
      expect(result!.id, equals(tripId));
      expect(result.tripName, equals('夏旅行'));
      expect(result.pins, hasLength(1));
      final PinDto pin = result.pins!.first;
      expect(pin.details, hasLength(1));
      final PinDetailDto detail = pin.details!.first;
      expect(detail.name, equals('ランチ'));
      expect(result.routes, hasLength(1));
      expect(result.routes!.first.orderIndex, 0);
      verify(
        mockPinsQuery.orderBy('visitStartDate', descending: false),
      ).called(1);
      verify(
        mockPinDetailsQuery.orderBy('startDate', descending: false),
      ).called(1);
      verify(
        mockRoutesQuery.orderBy('orderIndex', descending: false),
      ).called(1);
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

    test('旅行取得時に例外が発生した場合はnullを返す', () async {
      when(
        mockTripEntriesCollection.doc(any),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getTripEntryById('trip001');

      expect(result, isNull);
    });

    test('グループIDとtripYearで旅行一覧を取得し、orderByを適用する', () async {
      const groupId = 'group001';
      const year = 2024;
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockTripEntriesCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.where('tripYear', isEqualTo: year)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('tripStartDate', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('trip001');
      when(mockDoc.data()).thenReturn({
        'groupId': groupId,
        'tripName': '冬旅行',
        'tripYear': year,
        'tripStartDate': Timestamp.fromDate(DateTime(2024, 12, 20)),
        'tripEndDate': Timestamp.fromDate(DateTime(2024, 12, 25)),
        'tripMemo': '温泉巡り',
      });

      final result = await service.getTripEntriesByGroupIdAndYear(
        groupId,
        year,
        orderBy: const [OrderBy('tripStartDate', descending: false)],
      );

      expect(result, hasLength(1));
      verify(mockQuery.orderBy('tripStartDate', descending: false)).called(1);
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
