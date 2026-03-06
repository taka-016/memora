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
        longitude: 135.0,
        locationName: '大阪',
      );

      final entity = PinMapper.toEntity(dto);

      expect(entity.pinId, 'pin-1');
      expect(entity.tripId, 'trip-1');
      expect(entity.groupId, 'group-1');
      expect(entity.locationName, '大阪');
    });

    test('リスト変換ができる', () {
      final dtos = [
        PinDto(
          pinId: 'pin-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.0,
          longitude: 135.0,
        ),
      ];

      final entities = PinMapper.toEntityList(dtos);

      expect(entities, hasLength(1));
      expect(entities.first.pinId, 'pin-1');
    });
  });
}
