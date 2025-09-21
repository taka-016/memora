import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_trip_entry_mapper.dart';
import 'package:memora/domain/entities/trip_entry.dart';

import 'firestore_trip_entry_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreTripEntryMapper', () {
    test('FirestoreのDocumentSnapshotからTripEntryへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('trip001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'tripName': 'テスト旅行',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 6, 10)),
        'tripMemo': 'テストメモ',
      });

      final tripEntry = FirestoreTripEntryMapper.fromFirestore(mockDoc);

      expect(tripEntry.id, 'trip001');
      expect(tripEntry.groupId, 'group001');
      expect(tripEntry.tripName, 'テスト旅行');
      expect(tripEntry.tripStartDate, DateTime(2025, 6, 1));
      expect(tripEntry.tripEndDate, DateTime(2025, 6, 10));
      expect(tripEntry.tripMemo, 'テストメモ');
      expect(tripEntry.pins, isEmpty);
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('trip002');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group002',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 7, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 7, 5)),
      });

      final tripEntry = FirestoreTripEntryMapper.fromFirestore(mockDoc);

      expect(tripEntry.id, 'trip002');
      expect(tripEntry.groupId, 'group002');
      expect(tripEntry.tripName, null);
      expect(tripEntry.tripStartDate, DateTime(2025, 7, 1));
      expect(tripEntry.tripEndDate, DateTime(2025, 7, 5));
      expect(tripEntry.tripMemo, null);
      expect(tripEntry.pins, isEmpty);
    });

    test('Firestoreのデータがnullの場合はデフォルト値に変換される', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('trip003');
      when(mockDoc.data()).thenReturn({});
      final before = DateTime.now();

      final tripEntry = FirestoreTripEntryMapper.fromFirestore(mockDoc);
      final after = DateTime.now();

      expect(tripEntry.id, 'trip003');
      expect(tripEntry.groupId, '');
      expect(tripEntry.tripName, isNull);
      expect(tripEntry.tripMemo, isNull);
      expect(
        tripEntry.tripStartDate.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        tripEntry.tripStartDate.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        tripEntry.tripEndDate.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        tripEntry.tripEndDate.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(tripEntry.pins, isEmpty);
    });

    test('TripEntryからFirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group001');
      expect(data['tripName'], 'テスト旅行');
      expect(data['tripStartDate'], isA<Timestamp>());
      expect(data['tripEndDate'], isA<Timestamp>());
      expect(data['tripMemo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip002',
        groupId: 'group002',
        tripStartDate: DateTime(2025, 7, 1),
        tripEndDate: DateTime(2025, 7, 5),
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group002');
      expect(data['tripName'], null);
      expect(data['tripStartDate'], isA<Timestamp>());
      expect(data['tripEndDate'], isA<Timestamp>());
      expect(data['tripMemo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
