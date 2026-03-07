import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';

void main() {
  group('PinMapper', () {
    test('PinDtoをPinエンティティに変換できる', () {
      final dto = PinDto(
        pinId: 'pin-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        latitude: 35.0,
        longitude: 139.0,
      );

      final entity = PinMapper.toEntity(dto);

      expect(entity.pinId, 'pin-1');
      expect(entity.tripId, 'trip-1');
      expect(entity.groupId, 'group-1');
      expect(entity.latitude, 35.0);
      expect(entity.longitude, 139.0);
    });

    test('PinDtoリストをエンティティリストに変換できる', () {
      final dtos = [
        PinDto(
          pinId: 'pin-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.0,
          longitude: 139.0,
        ),
        PinDto(
          pinId: 'pin-2',
          tripId: 'trip-2',
          groupId: 'group-2',
          latitude: 36.0,
          longitude: 140.0,
        ),
      ];

      final entities = PinMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].pinId, 'pin-1');
      expect(entities[1].pinId, 'pin-2');
    });
  });
}
