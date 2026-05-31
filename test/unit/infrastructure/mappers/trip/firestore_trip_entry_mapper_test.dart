import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

import 'firestore_trip_entry_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreTripEntryMapper', () {
    test('FirestoreドキュメントからTripEntryDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('trip001');
      when(doc.data()).thenReturn({
        'groupId': 'group001',
        'year': 2025,
        'name': '夏旅行',
        'startDate': Timestamp.fromDate(DateTime(2025, 8, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 8, 3)),
        'memo': '海に行く',
      });
      const tasks = [
        TaskDto(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '予約',
          isCompleted: false,
        ),
      ];
      const itineraryItems = [
        ItineraryItemDto(id: 'item001', tripId: 'trip001', name: '朝食'),
      ];

      final result = FirestoreTripEntryMapper.fromFirestore(
        doc,
        fallbackTripYear: 2026,
        tasks: tasks,
        itineraryItems: itineraryItems,
      );

      expect(result.id, 'trip001');
      expect(result.groupId, 'group001');
      expect(result.year, 2025);
      expect(result.name, '夏旅行');
      expect(result.startDate, DateTime(2025, 8, 1));
      expect(result.endDate, DateTime(2025, 8, 3));
      expect(result.memo, '海に行く');
      expect(result.tasks, tasks);
      expect(result.itineraryItems, itineraryItems);
    });

    test('year欠損時はstartDateの年を補完する', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('trip002');
      when(doc.data()).thenReturn({
        'groupId': 'group002',
        'startDate': Timestamp.fromDate(DateTime(2024, 12, 31)),
      });

      final result = FirestoreTripEntryMapper.fromFirestore(
        doc,
        fallbackTripYear: 2026,
      );

      expect(result.year, 2024);
      expect(result.groupId, 'group002');
      expect(result.startDate, DateTime(2024, 12, 31));
      expect(result.endDate, isNull);
    });

    test('TripEntryを新規作成用FirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        year: 2025,
        name: 'テスト旅行',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        memo: 'テストメモ',
      );

      final data = FirestoreTripEntryMapper.toCreateFirestore(tripEntry);

      expect(data['groupId'], 'group001');
      expect(data['year'], 2025);
      expect(data['name'], 'テスト旅行');
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['memo'], 'テストメモ');
      expect(data.containsKey('tripYear'), isFalse);
      expect(data.containsKey('tripName'), isFalse);
      expect(data.containsKey('tripStartDate'), isFalse);
      expect(data.containsKey('tripEndDate'), isFalse);
      expect(data.containsKey('tripMemo'), isFalse);
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('旅行期間が未設定でも更新用FirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip002',
        groupId: 'group002',
        year: 2025,
      );

      final data = FirestoreTripEntryMapper.toUpdateFirestore(tripEntry);

      expect(data['groupId'], 'group002');
      expect(data['year'], 2025);
      expect(data['name'], null);
      expect(data['startDate'], isNull);
      expect(data['endDate'], isNull);
      expect(data['memo'], null);
      expect(data.containsKey('tripYear'), isFalse);
      expect(data.containsKey('tripName'), isFalse);
      expect(data.containsKey('tripStartDate'), isFalse);
      expect(data.containsKey('tripEndDate'), isFalse);
      expect(data.containsKey('tripMemo'), isFalse);
      expect(data.containsKey('createdAt'), isFalse);
      expect(data['updatedAt'], isA<FieldValue>());
    });
  });
}
