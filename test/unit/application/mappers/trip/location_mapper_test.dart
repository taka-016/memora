import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/domain/entities/trip/location.dart';

void main() {
  group('LocationMapper', () {
    test('DTOからエンティティへ変換できる', () {
      const dto = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      final entity = LocationMapper.toEntity(dto);

      expect(entity, isA<Location>());
      expect(entity.id, dto.id);
      expect(entity.tripId, dto.tripId);
      expect(entity.groupId, dto.groupId);
      expect(entity.name, dto.name);
      expect(entity.latitude, dto.latitude);
      expect(entity.longitude, dto.longitude);
    });

    test('エンティティからDTOへ変換できる', () {
      final entity = Location(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      final dto = LocationMapper.toDto(entity);

      expect(dto, isA<LocationDto>());
      expect(dto.id, entity.id);
      expect(dto.tripId, entity.tripId);
      expect(dto.groupId, entity.groupId);
      expect(dto.name, entity.name);
      expect(dto.latitude, entity.latitude);
      expect(dto.longitude, entity.longitude);
    });
  });
}
