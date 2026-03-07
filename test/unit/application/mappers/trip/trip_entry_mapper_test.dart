import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';

void main() {
  group('TripEntryMapper', () {
    test('TripEntryDtoをTripEntryエンティティへ変換できる', () {
      final dto = TripEntryDto(
        id: 'trip-1',
        groupId: 'group-1',
        tripYear: 2024,
        tripName: '夏の旅行',
        pins: [
          PinDto(
            pinId: 'pin-1',
            tripId: 'trip-1',
            groupId: 'group-1',
            latitude: 35.0,
            longitude: 139.0,
          ),
        ],
        tasks: [
          TaskDto(
            id: 'task-1',
            tripId: 'trip-1',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
      );

      final entity = TripEntryMapper.toEntity(dto);

      expect(entity.id, 'trip-1');
      expect(entity.groupId, 'group-1');
      expect(entity.tripYear, 2024);
      expect(entity.pins, hasLength(1));
      expect(entity.tasks, hasLength(1));
    });

    test('TripEntryDtoリストをエンティティリストへ変換できる', () {
      final dtos = [
        TripEntryDto(id: 'trip-1', groupId: 'group-1', tripYear: 2024),
        TripEntryDto(id: 'trip-2', groupId: 'group-2', tripYear: 2025),
      ];

      final entities = TripEntryMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].id, 'trip-1');
      expect(entities[1].id, 'trip-2');
    });
  });
}
