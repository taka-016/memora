import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_entry_repository.dart';
import 'package:memora/domain/entities/trip_entry.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
])
import 'firestore_trip_entry_repository_test.mocks.dart';

void main() {
  group('FirestoreTripEntryRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreTripEntryRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc2;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('trip_entries')).thenReturn(mockCollection);
      repository = FirestoreTripEntryRepository(firestore: mockFirestore);
    });

    test('saveTripEntryがtrip_entries collectionに旅行情報をaddする', () async {
      final tripEntry = TripEntry(
        id: 'trip001',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveTripEntry(tripEntry);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('tripName', 'テスト旅行'),
              containsPair('tripMemo', 'テストメモ'),
              contains('tripStartDate'),
              contains('tripEndDate'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('getTripEntriesがFirestoreからTripEntryのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('trip001');
      when(mockDoc1.data()).thenReturn({
        'tripName': 'テスト旅行1',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 6, 10)),
        'tripMemo': 'テストメモ1',
      });
      when(mockDoc2.id).thenReturn('trip002');
      when(mockDoc2.data()).thenReturn({
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 7, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 7, 5)),
      });

      final result = await repository.getTripEntries();

      expect(result.length, 2);
      expect(result[0].id, 'trip001');
      expect(result[0].tripName, 'テスト旅行1');
      expect(result[0].tripMemo, 'テストメモ1');
      expect(result[1].id, 'trip002');
      expect(result[1].tripName, null);
      expect(result[1].tripMemo, null);
    });

    test('getTripEntriesがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getTripEntries();

      expect(result, isEmpty);
    });

    test('deleteTripEntryがtrip_entries collectionの該当ドキュメントを削除する', () async {
      const tripId = 'trip001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteTripEntry(tripId);

      verify(mockCollection.doc(tripId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('getTripEntryByIdが特定の旅行を返す', () async {
      const tripId = 'trip001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(tripId);
      when(mockDocSnapshot.data()).thenReturn({
        'tripName': 'テスト旅行',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 6, 10)),
        'tripMemo': 'テストメモ',
      });

      final result = await repository.getTripEntryById(tripId);

      expect(result, isNotNull);
      expect(result!.id, tripId);
      expect(result.tripName, 'テスト旅行');
    });

    test('getTripEntryByIdが存在しない旅行でnullを返す', () async {
      const tripId = 'nonexistent';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(tripId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.getTripEntryById(tripId);

      expect(result, isNull);
    });
  });
}