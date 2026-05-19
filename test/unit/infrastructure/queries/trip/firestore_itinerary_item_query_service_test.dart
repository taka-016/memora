import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_itinerary_item_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreItineraryItemQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>>
    mockItineraryItemsCollection;
    late FirestoreItineraryItemQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockItineraryItemsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('itinerary_items'),
      ).thenReturn(mockItineraryItemsCollection);
      service = FirestoreItineraryItemQueryService(firestore: mockFirestore);
    });

    test('旅行IDで旅程項目一覧を取得しorderByを複数適用できる', () async {
      const tripId = 'trip001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockItineraryItemsCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('startDateTime', descending: false),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('endDateTime', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('item001');
      when(mockDoc.data()).thenReturn({
        'tripId': tripId,
        'name': '朝食',
        'startDateTime': Timestamp.fromDate(DateTime(2024, 1, 2, 8)),
        'endDateTime': Timestamp.fromDate(DateTime(2024, 1, 2, 9)),
        'memo': 'ホテルで朝食',
      });

      final result = await service.getItineraryItemsByTripId(
        tripId,
        orderBy: const [
          OrderBy('startDateTime', descending: false),
          OrderBy('endDateTime', descending: false),
        ],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<ItineraryItemDto>());
      expect(result.first.id, 'item001');
      expect(result.first.name, '朝食');
      verify(mockQuery.orderBy('startDateTime', descending: false)).called(1);
      verify(mockQuery.orderBy('endDateTime', descending: false)).called(1);
    });

    test('取得時に例外が発生した場合は空リストを返す', () async {
      when(
        mockItineraryItemsCollection.where(
          'tripId',
          isEqualTo: anyNamed('isEqualTo'),
        ),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getItineraryItemsByTripId('trip001');

      expect(result, isEmpty);
    });
  });
}
