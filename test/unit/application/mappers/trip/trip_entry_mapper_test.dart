import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';

void main() {
  group('TripEntryMapper', () {
    test('TripEntryDtoをTripEntryエンティティに変換できる', () {
      final dto = TripEntryDto(
        id: 'trip-1',
        groupId: 'group-1',
        tripYear: 2024,
        pins: [
          PinDto(
            pinId: 'pin-1',
            tripId: 'trip-1',
            groupId: 'group-1',
            latitude: 35.0,
            longitude: 135.0,
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
      expect(entity.pins, hasLength(1));
      expect(entity.tasks, hasLength(1));
      expect(entity.pins.first.pinId, 'pin-1');
      expect(entity.tasks.first.id, 'task-1');
    });

    test('リスト変換ができる', () {
      final dtos = [
        TripEntryDto(id: 'trip-1', groupId: 'group-1', tripYear: 2024),
      ];

      final entities = TripEntryMapper.toEntityList(dtos);

      expect(entities, hasLength(1));
      expect(entities.first.id, 'trip-1');
    });
  });
}
