import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreTripEntryMapper', () {
    test('FirestoreドキュメントからTripEntryDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'trip001',
        data: {
          'groupId': 'group001',
          'tripYear': 2025,
          'tripName': 'テスト旅行',
          'tripStartDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
          'tripEndDate': Timestamp.fromDate(DateTime(2025, 6, 10)),
        },
      );
      final pins = [
        PinDto(
          pinId: 'pin001',
          tripId: 'trip001',
          groupId: 'group001',
          latitude: 35,
          longitude: 135,
        ),
      ];
      final tasks = [
        TaskDto(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];

      final dto = FirestoreTripEntryMapper.fromFirestore(
        doc,
        pins: pins,
        tasks: tasks,
      );

      expect(dto.id, 'trip001');
      expect(dto.groupId, 'group001');
      expect(dto.tripYear, 2025);
      expect(dto.tripName, 'テスト旅行');
      expect(dto.tripStartDate, DateTime(2025, 6, 1));
      expect(dto.tripEndDate, DateTime(2025, 6, 10));
      expect(dto.pins, hasLength(1));
      expect(dto.tasks, hasLength(1));
    });

    test('tripYearがない場合は開始日を使う', () {
      final doc = FakeDocumentSnapshot(
        docId: 'trip002',
        data: {
          'groupId': 'group002',
          'tripStartDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        },
      );

      final dto = FirestoreTripEntryMapper.fromFirestore(doc);

      expect(dto.tripYear, 2024);
    });

    test('TripEntryをFirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip003',
        groupId: 'group003',
        tripYear: 2025,
        tripName: '旅行',
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group003');
      expect(data['tripYear'], 2025);
      expect(data['tripName'], '旅行');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
