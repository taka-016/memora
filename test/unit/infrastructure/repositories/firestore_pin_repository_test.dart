import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_pin_repository.dart';
import 'package:memora/domain/entities/pin.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'firestore_pin_repository_test.mocks.dart';

void main() {
  group('FirestorePinRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestorePinRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc2;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('pins')).thenReturn(mockCollection);
      repository = FirestorePinRepository(firestore: mockFirestore);
    });

    test('savePinがPinエンティティをFirestoreに保存する', () async {
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-marker-id',
        latitude: 35.0,
        longitude: 139.0,
      );
      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.savePin(pin);

      verify(
        mockCollection.add(
          argThat(
            allOf(
              containsPair('pinId', 'test-marker-id'),
              containsPair('latitude', 35.0),
              containsPair('longitude', 139.0),
            ),
          ),
        ),
      ).called(1);
    });

    test('getPinsがFirestoreからPinのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('abc123');
      when(
        mockDoc1.data(),
      ).thenReturn({'pinId': 'def123', 'latitude': 35.0, 'longitude': 139.0});
      when(mockDoc2.id).thenReturn('abc456');
      when(
        mockDoc2.data(),
      ).thenReturn({'pinId': 'def456', 'latitude': 36.0, 'longitude': 140.0});

      final result = await repository.getPins();

      expect(result.length, 2);
      expect(result[0].id, 'abc123');
      expect(result[0].pinId, 'def123');
      expect(result[0].latitude, 35.0);
      expect(result[0].longitude, 139.0);
      expect(result[1].id, 'abc456');
      expect(result[1].pinId, 'def456');
      expect(result[1].latitude, 36.0);
      expect(result[1].longitude, 140.0);
    });

    test('getPinsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getPins();

      expect(result, isEmpty);
    });

    test('deletePinがpins collectionの該当ドキュメントを削除する', () async {
      const pinId = 'test-marker-id';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(
        mockCollection.where('pinId', isEqualTo: pinId),
      ).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('dummy_id');
      when(mockFirestore.collection('pins')).thenReturn(mockCollection);
      when(mockCollection.doc('dummy_id')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deletePin(pinId);

      verify(mockCollection.where('pinId', isEqualTo: pinId)).called(1);
      verify(mockCollection.get()).called(1);
      verify(mockCollection.doc('dummy_id')).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('getPinsByTripIdがtripIdで絞り込んだPinのリストを返す', () async {
      const tripId = 'trip123';
      when(
        mockCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockCollection);
      when(mockCollection.orderBy('visitStartDate')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('abc123');
      when(mockDoc1.data()).thenReturn({
        'pinId': 'pin123',
        'tripId': tripId,
        'latitude': 35.0,
        'longitude': 139.0,
      });
      when(mockDoc2.id).thenReturn('abc456');
      when(mockDoc2.data()).thenReturn({
        'pinId': 'pin456',
        'tripId': tripId,
        'latitude': 36.0,
        'longitude': 140.0,
      });

      final result = await repository.getPinsByTripId(tripId);

      expect(result.length, 2);
      expect(result[0].id, 'abc123');
      expect(result[0].pinId, 'pin123');
      expect(result[0].tripId, tripId);
      expect(result[1].id, 'abc456');
      expect(result[1].pinId, 'pin456');
      expect(result[1].tripId, tripId);

      verify(mockCollection.where('tripId', isEqualTo: tripId)).called(1);
    });

    test('getPinsByTripIdがvisitStartDateの昇順でソートして返す', () async {
      const tripId = 'trip123';
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockCollection);
      when(mockCollection.orderBy('visitStartDate')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      // より早い日付のピン
      when(mockDoc1.id).thenReturn('abc123');
      when(mockDoc1.data()).thenReturn({
        'pinId': 'pin123',
        'tripId': tripId,
        'latitude': 35.0,
        'longitude': 139.0,
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      // より遅い日付のピン
      when(mockDoc2.id).thenReturn('abc456');
      when(mockDoc2.data()).thenReturn({
        'pinId': 'pin456',
        'tripId': tripId,
        'latitude': 36.0,
        'longitude': 140.0,
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 3)),
      });

      final result = await repository.getPinsByTripId(tripId);

      expect(result.length, 2);
      expect(result[0].visitStartDate, DateTime(2024, 1, 1));
      expect(result[1].visitStartDate, DateTime(2024, 1, 3));

      verify(mockCollection.where('tripId', isEqualTo: tripId)).called(1);
      verify(mockCollection.orderBy('visitStartDate')).called(1);
    });

    test('getPinsByTripIdがvisitStartDateがnullのピンも含めて昇順でソートして返す', () async {
      const tripId = 'trip123';
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc3 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockCollection);
      when(mockCollection.orderBy('visitStartDate')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2, mockDoc3]);

      // nullの日付のピン（最初に配置される）
      when(mockDoc1.id).thenReturn('abc111');
      when(mockDoc1.data()).thenReturn({
        'pinId': 'pin111',
        'tripId': tripId,
        'latitude': 35.0,
        'longitude': 139.0,
        'visitStartDate': null,
      });

      // より早い日付のピン
      when(mockDoc2.id).thenReturn('abc123');
      when(mockDoc2.data()).thenReturn({
        'pinId': 'pin123',
        'tripId': tripId,
        'latitude': 35.0,
        'longitude': 139.0,
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      // より遅い日付のピン
      when(mockDoc3.id).thenReturn('abc456');
      when(mockDoc3.data()).thenReturn({
        'pinId': 'pin456',
        'tripId': tripId,
        'latitude': 36.0,
        'longitude': 140.0,
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 3)),
      });

      final result = await repository.getPinsByTripId(tripId);

      expect(result.length, 3);
      expect(result[0].visitStartDate, null);
      expect(result[1].visitStartDate, DateTime(2024, 1, 1));
      expect(result[2].visitStartDate, DateTime(2024, 1, 3));

      verify(mockCollection.where('tripId', isEqualTo: tripId)).called(1);
      verify(mockCollection.orderBy('visitStartDate')).called(1);
    });

    test('getPinsByTripIdがエラー時に空のリストを返す', () async {
      const tripId = 'trip123';
      when(
        mockCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockCollection);
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getPinsByTripId(tripId);

      expect(result, isEmpty);
    });

    test('savePinWithTripがPinエンティティをFirestoreに保存する', () async {
      final pin = Pin(
        id: 'pin123',
        pinId: 'pin123',
        tripId: 'trip123',
        latitude: 35.0,
        longitude: 139.0,
        visitStartDate: DateTime(2024, 1, 1),
        visitEndDate: DateTime(2024, 1, 3),
        visitMemo: 'テストメモ',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.savePinWithTrip(pin);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('pinId', 'pin123'),
              containsPair('tripId', 'trip123'),
              containsPair('latitude', 35.0),
              containsPair('longitude', 139.0),
              containsPair('visitMemo', 'テストメモ'),
              contains('visitStartDate'),
              contains('visitEndDate'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('deletePinsByTripIdがtripIdに紐づく全てのpinを削除する', () async {
      const tripId = 'trip123';
      final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();

      when(
        mockCollection.where('tripId', isEqualTo: tripId),
      ).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('doc1');
      when(mockDoc2.id).thenReturn('doc2');
      when(mockFirestore.collection('pins')).thenReturn(mockCollection);
      when(mockCollection.doc('doc1')).thenReturn(mockDocRef1);
      when(mockCollection.doc('doc2')).thenReturn(mockDocRef2);
      when(mockDocRef1.delete()).thenAnswer((_) async {});
      when(mockDocRef2.delete()).thenAnswer((_) async {});

      await repository.deletePinsByTripId(tripId);

      verify(mockCollection.where('tripId', isEqualTo: tripId)).called(1);
      verify(mockCollection.get()).called(1);
      verify(mockCollection.doc('doc1')).called(1);
      verify(mockCollection.doc('doc2')).called(1);
      verify(mockDocRef1.delete()).called(1);
      verify(mockDocRef2.delete()).called(1);
    });
  });
}
