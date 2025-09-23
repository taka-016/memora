import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_entry_repository.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import '../../../helpers/test_exception.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
  WriteBatch,
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
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('trip_entries')).thenReturn(mockCollection);
      repository = FirestoreTripEntryRepository(firestore: mockFirestore);
    });

    test(
      'saveTripEntryがtrip_entries collectionに旅行情報をaddし、ドキュメントIDを返す',
      () async {
        final tripEntry = TripEntry(
          id: 'trip001',
          groupId: 'group001',
          tripName: 'テスト旅行',
          tripStartDate: DateTime(2025, 6, 1),
          tripEndDate: DateTime(2025, 6, 10),
          tripMemo: 'テストメモ',
        );

        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockDocRef.id).thenReturn('generated-doc-id');
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

        final result = await repository.saveTripEntry(tripEntry);

        expect(result, equals('generated-doc-id'));
        verify(
          mockCollection.add(
            argThat(
              predicate<Map<String, dynamic>>((map) {
                return map['groupId'] == 'group001' &&
                    map['tripName'] == 'テスト旅行' &&
                    map['tripMemo'] == 'テストメモ' &&
                    map.containsKey('tripStartDate') &&
                    map.containsKey('tripEndDate') &&
                    map.containsKey('createdAt');
              }),
            ),
          ),
        ).called(1);
      },
    );

    test('getTripEntriesがFirestoreからTripEntryのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('trip001');
      when(mockDoc1.data()).thenReturn({
        'groupId': 'group001',
        'tripName': 'テスト旅行1',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 6, 10)),
        'tripMemo': 'テストメモ1',
      });
      when(mockDoc2.id).thenReturn('trip002');
      when(mockDoc2.data()).thenReturn({
        'groupId': 'group002',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 7, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 7, 5)),
      });

      final result = await repository.getTripEntries();

      expect(result.length, 2);
      expect(result[0].id, 'trip001');
      expect(result[0].groupId, 'group001');
      expect(result[0].tripName, 'テスト旅行1');
      expect(result[0].tripMemo, 'テストメモ1');
      expect(result[0].pins, isEmpty);
      expect(result[1].id, 'trip002');
      expect(result[1].groupId, 'group002');
      expect(result[1].tripName, null);
      expect(result[1].tripMemo, null);
      expect(result[1].pins, isEmpty);
    });

    test('getTripEntriesがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(TestException('Firestore error'));

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
        'groupId': 'group001',
        'tripName': 'テスト旅行',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 6, 10)),
        'tripMemo': 'テストメモ',
      });

      final result = await repository.getTripEntryById(tripId);

      expect(result, isNotNull);
      expect(result!.id, tripId);
      expect(result.groupId, 'group001');
      expect(result.tripName, 'テスト旅行');
      expect(result.pins, isEmpty);
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

    test('deleteTripEntriesByGroupIdが指定したgroupIdの全旅行エントリを削除する', () async {
      const groupId = 'group001';
      final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.reference).thenReturn(mockDocRef1);
      when(mockDoc2.reference).thenReturn(mockDocRef2);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteTripEntriesByGroupId(groupId);

      verify(mockCollection.where('groupId', isEqualTo: groupId)).called(1);
      verify(mockQuery.get()).called(1);
      verify(mockFirestore.batch()).called(1);
      verify(mockBatch.delete(mockDocRef1)).called(1);
      verify(mockBatch.delete(mockDocRef2)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('getTripEntriesByGroupIdAndYearがソート条件なしで呼び出される', () async {
      const groupId = 'group001';
      const year = 2024;
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year + 1, 1, 1);

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(
          'tripStartDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
        ),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(
          'tripStartDate',
          isLessThan: Timestamp.fromDate(endOfYear),
        ),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      final result = await repository.getTripEntriesByGroupIdAndYear(
        groupId,
        year,
      );

      expect(result, isEmpty);
      verify(mockCollection.where('groupId', isEqualTo: groupId)).called(1);
      verify(
        mockQuery.where(
          'tripStartDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
        ),
      ).called(1);
      verify(
        mockQuery.where(
          'tripStartDate',
          isLessThan: Timestamp.fromDate(endOfYear),
        ),
      ).called(1);
      verify(mockQuery.get()).called(1);
      verifyNever(mockQuery.orderBy(any, descending: anyNamed('descending')));
    });

    test('getTripEntriesByGroupIdAndYearがソート条件ありで呼び出される', () async {
      const groupId = 'group001';
      const year = 2024;
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year + 1, 1, 1);
      final orderBy = [
        const OrderBy('tripStartDate', descending: false),
        const OrderBy('tripName', descending: true),
      ];

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(
          'tripStartDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
        ),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(
          'tripStartDate',
          isLessThan: Timestamp.fromDate(endOfYear),
        ),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('tripStartDate', descending: false),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('tripName', descending: true),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      final result = await repository.getTripEntriesByGroupIdAndYear(
        groupId,
        year,
        orderBy: orderBy,
      );

      expect(result, isEmpty);
      verify(mockQuery.orderBy('tripStartDate', descending: false)).called(1);
      verify(mockQuery.orderBy('tripName', descending: true)).called(1);
    });
  });
}
