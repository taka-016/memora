import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_route_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_route_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
  WriteBatch,
])
void main() {
  group('FirestoreRouteRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockRoutesCollection;
    late MockWriteBatch mockBatch;
    late FirestoreRouteRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockRoutesCollection = MockCollectionReference<Map<String, dynamic>>();
      mockBatch = MockWriteBatch();

      when(mockFirestore.collection('routes')).thenReturn(mockRoutesCollection);
      when(mockFirestore.batch()).thenReturn(mockBatch);

      repository = FirestoreRouteRepository(firestore: mockFirestore);
    });

    test('saveRoutesでルートを保存する', () async {
      const tripId = 'trip001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final route = Route(
        id: 'route001',
        tripId: tripId,
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      when(mockRoutesCollection.doc(route.id)).thenReturn(mockDocRef);
      when(mockBatch.set(any, any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.saveRoutes(tripId, [route]);

      verify(mockRoutesCollection.doc(route.id)).called(1);
      verify(mockBatch.set(mockDocRef, any)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('updateRoutesで既存ルートを削除してから新規保存する', () async {
      const tripId = 'trip001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockExistingRef = MockDocumentReference<Map<String, dynamic>>();
      final mockNewDocRef = MockDocumentReference<Map<String, dynamic>>();
      final route = Route(
        id: 'route001',
        tripId: tripId,
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      when(
        mockRoutesCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.reference).thenReturn(mockExistingRef);
      when(mockRoutesCollection.doc(route.id)).thenReturn(mockNewDocRef);
      when(mockBatch.delete(any)).thenReturn(null);
      when(mockBatch.set(any, any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.updateRoutes(tripId, [route]);

      verify(mockBatch.delete(mockExistingRef)).called(1);
      verify(mockRoutesCollection.doc(route.id)).called(1);
      verify(mockBatch.set(mockNewDocRef, any)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('deleteRoutesで関連ルートを削除する', () async {
      const tripId = 'trip001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockRef = MockDocumentReference<Map<String, dynamic>>();

      when(
        mockRoutesCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.reference).thenReturn(mockRef);
      when(mockBatch.delete(any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteRoutes(tripId);

      verify(mockBatch.delete(mockRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('deleteRoutesByPinIdで出発・到着ピンのルートを削除する', () async {
      const pinId = 'pin001';
      final mockDepartureQuery = MockQuery<Map<String, dynamic>>();
      final mockArrivalQuery = MockQuery<Map<String, dynamic>>();
      final mockDepartureSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockArrivalSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDepartureDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockArrivalDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDepartureRef = MockDocumentReference<Map<String, dynamic>>();
      final mockArrivalRef = MockDocumentReference<Map<String, dynamic>>();

      when(
        mockRoutesCollection.where('departurePinId', isEqualTo: pinId),
      ).thenReturn(mockDepartureQuery);
      when(
        mockRoutesCollection.where('arrivalPinId', isEqualTo: pinId),
      ).thenReturn(mockArrivalQuery);
      when(
        mockDepartureQuery.get(),
      ).thenAnswer((_) async => mockDepartureSnapshot);
      when(mockArrivalQuery.get()).thenAnswer((_) async => mockArrivalSnapshot);
      when(mockDepartureSnapshot.docs).thenReturn([mockDepartureDoc]);
      when(mockArrivalSnapshot.docs).thenReturn([mockArrivalDoc]);
      when(mockDepartureDoc.reference).thenReturn(mockDepartureRef);
      when(mockArrivalDoc.reference).thenReturn(mockArrivalRef);
      when(mockBatch.delete(any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteRoutesByPinId(pinId);

      verify(mockBatch.delete(mockDepartureRef)).called(1);
      verify(mockBatch.delete(mockArrivalRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('Firestore操作で例外が発生した場合はそのまま伝播する', () async {
      when(
        mockRoutesCollection.where('tripId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore'));

      expect(
        () => repository.updateRoutes('trip001', const []),
        throwsA(isA<TestException>()),
      );
    });
  });
}
