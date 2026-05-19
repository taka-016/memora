import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/mappers/trip/itinerary_item_mapper.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart' as entity;

void main() {
  group('ItineraryItemMapper', () {
    test('ItineraryItemDtoをItineraryItemエンティティに変換できる', () {
      final dto = ItineraryItemDto(
        id: 'item001',
        tripId: 'trip001',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      final item = ItineraryItemMapper.toEntity(dto);

      expect(
        item,
        entity.ItineraryItem(
          id: 'item001',
          tripId: 'trip001',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 8),
          endDateTime: DateTime(2024, 1, 2, 9),
          memo: 'ホテルで朝食',
        ),
      );
    });

    test('ItineraryItemDtoのリストをエンティティリストに変換できる', () {
      const dtos = [
        ItineraryItemDto(
          id: 'item001',
          tripId: 'trip001',
          name: '朝食',
        ),
        ItineraryItemDto(
          id: 'item002',
          tripId: 'trip001',
          name: '観光',
        ),
      ];

      final items = ItineraryItemMapper.toEntityList(dtos);

      expect(items, hasLength(2));
      expect(items[0].name, '朝食');
      expect(items[1].name, '観光');
    });
  });
}
