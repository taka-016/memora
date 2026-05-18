import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

void main() {
  group('TripEntryMapper', () {
    test('TripEntryDtoからTripEntryエンティティへ変換できる', () {
      final dto = TripEntryDto(
        id: 'trip-003',
        groupId: 'group-003',
        year: 2024,
        name: '夏の旅行',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 7, 5),
        memo: '海水浴に行く',
        pins: [
          PinDto(
            pinId: 'pin-010',
            tripId: 'trip-003',
            groupId: 'group-003',
            latitude: 34.0,
            longitude: 134.0,
            locationName: '海岸',
          ),
        ],
        tasks: [
          TaskDto(
            id: 'task-010',
            tripId: 'trip-003',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
        itineraryItems: [
          ItineraryItemDto(
            id: 'item-010',
            tripId: 'trip-003',
            orderIndex: 0,
            name: '朝食',
            startDateTime: DateTime(2024, 7, 2, 8),
            endDateTime: DateTime(2024, 7, 2, 9),
            memo: 'ホテルで朝食',
          ),
        ],
      );

      final entity = TripEntryMapper.toEntity(dto);

      expect(
        entity,
        TripEntry(
          id: 'trip-003',
          groupId: 'group-003',
          year: 2024,
          name: '夏の旅行',
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 5),
          memo: '海水浴に行く',
          pins: [
            Pin(
              pinId: 'pin-010',
              tripId: 'trip-003',
              groupId: 'group-003',
              latitude: 34.0,
              longitude: 134.0,
              locationName: '海岸',
            ),
          ],
          tasks: [
            Task(
              id: 'task-010',
              tripId: 'trip-003',
              orderIndex: 0,
              name: '準備',
              isCompleted: false,
            ),
          ],
          itineraryItems: [
            ItineraryItem(
              id: 'item-010',
              tripId: 'trip-003',
              orderIndex: 0,
              name: '朝食',
              startDateTime: DateTime(2024, 7, 2, 8),
              endDateTime: DateTime(2024, 7, 2, 9),
              memo: 'ホテルで朝食',
            ),
          ],
        ),
      );
    });

    test('TripEntryDtoのリストをエンティティリストに変換できる', () {
      final dtos = [
        TripEntryDto(
          id: 'trip-101',
          groupId: 'group-101',
          year: 2024,
          startDate: DateTime(2024, 4, 1),
          endDate: DateTime(2024, 4, 3),
        ),
        TripEntryDto(
          id: 'trip-102',
          groupId: 'group-102',
          year: 2024,
          startDate: DateTime(2024, 5, 1),
          endDate: DateTime(2024, 5, 5),
        ),
      ];

      final entities = TripEntryMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].id, 'trip-101');
      expect(entities[0].groupId, 'group-101');
      expect(entities[1].id, 'trip-102');
      expect(entities[1].groupId, 'group-102');
    });
  });
}
