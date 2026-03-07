import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
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
        'tripYear': 2025,
        'tripName': '夏旅行',
        'tripStartDate': Timestamp.fromDate(DateTime(2025, 8, 1)),
        'tripEndDate': Timestamp.fromDate(DateTime(2025, 8, 3)),
        'tripMemo': '海に行く',
      });
      const pins = [PinDto(pinId: 'pin001', latitude: 35, longitude: 139)];
      const tasks = [
        TaskDto(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '予約',
          isCompleted: false,
        ),
      ];

      final result = FirestoreTripEntryMapper.fromFirestore(
        doc,
        pins: pins,
        tasks: tasks,
      );

      expect(result.id, 'trip001');
      expect(result.groupId, 'group001');
      expect(result.tripYear, 2025);
      expect(result.tripName, '夏旅行');
      expect(result.tripStartDate, DateTime(2025, 8, 1));
      expect(result.tripEndDate, DateTime(2025, 8, 3));
      expect(result.tripMemo, '海に行く');
      expect(result.pins, pins);
      expect(result.tasks, tasks);
    });

    test('tripYear欠損時はtripStartDateの年を補完する', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('trip002');
      when(doc.data()).thenReturn({
        'groupId': 'group002',
        'tripStartDate': Timestamp.fromDate(DateTime(2024, 12, 31)),
      });

      final result = FirestoreTripEntryMapper.fromFirestore(doc);

      expect(result.tripYear, 2024);
      expect(result.groupId, 'group002');
      expect(result.tripStartDate, DateTime(2024, 12, 31));
      expect(result.tripEndDate, isNull);
    });

    test('TripEntryからFirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        tripYear: 2025,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group001');
      expect(data['tripYear'], 2025);
      expect(data['tripName'], 'テスト旅行');
      expect(data['tripStartDate'], isA<Timestamp>());
      expect(data['tripEndDate'], isA<Timestamp>());
      expect(data['tripMemo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('旅行期間が未設定の場合はtripYearのみで保存できる', () {
      final tripEntry = TripEntry(
        id: 'trip002',
        groupId: 'group002',
        tripYear: 2025,
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group002');
      expect(data['tripYear'], 2025);
      expect(data['tripName'], null);
      expect(data['tripStartDate'], isNull);
      expect(data['tripEndDate'], isNull);
      expect(data['tripMemo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
