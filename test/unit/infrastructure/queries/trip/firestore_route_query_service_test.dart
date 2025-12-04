import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/queries/trip/firestore_route_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_route_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreRouteQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockRoutesCollection;
    late FirestoreRouteQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockRoutesCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('routes')).thenReturn(mockRoutesCollection);
      service = FirestoreRouteQueryService(firestore: mockFirestore);
    });

    test('旅行IDでルート一覧を取得しorderByを適用できる', () async {
      const tripId = 'trip001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockRoutesCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('orderIndex', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 0,
        'departurePinId': 'pinA',
        'arrivalPinId': 'pinB',
        'travelMode': 'DRIVE',
      });

      final result = await service.getRoutesByTripId(
        tripId,
        orderBy: const [OrderBy('orderIndex', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<RouteDto>());
      verify(mockQuery.orderBy('orderIndex', descending: false)).called(1);
    });

    test('取得時に例外が発生した場合は空リストを返す', () async {
      when(
        mockRoutesCollection.where('tripId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getRoutesByTripId('trip001');

      expect(result, isEmpty);
    });
  });
}
