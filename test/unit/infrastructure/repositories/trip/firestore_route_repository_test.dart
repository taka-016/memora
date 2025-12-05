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

    test('saveRouteでルートを保存する', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final route = Route(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      when(mockRoutesCollection.doc('trip001_0')).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      await repository.saveRoute(route);

      verify(mockRoutesCollection.doc('trip001_0')).called(1);
      verify(mockDocRef.set(any)).called(1);
    });

    test('updateRouteで既存ルートを上書き保存する', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final route = Route(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      when(mockRoutesCollection.doc('trip001_0')).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      await repository.updateRoute(route);

      verify(mockRoutesCollection.doc('trip001_0')).called(1);
      verify(mockDocRef.set(any)).called(1);
    });

    test('deleteRouteで単一ルートを削除する', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockRoutesCollection.doc('route001')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteRoute('route001');

      verify(mockRoutesCollection.doc('route001')).called(1);
      verify(mockDocRef.delete()).called(1);
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
      when(mockRoutesCollection.doc(any)).thenThrow(TestException('firestore'));

      final route = Route(
        tripId: 'tripId',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      expect(() => repository.saveRoute(route), throwsA(isA<TestException>()));
    });
  });
}
