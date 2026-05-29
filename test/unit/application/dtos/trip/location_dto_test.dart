import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';

void main() {
  group('LocationDto', () {
    test('場所情報を保持できる', () {
      const dto = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      expect(dto.id, 'location-1');
      expect(dto.tripId, 'trip-1');
      expect(dto.groupId, 'group-1');
      expect(dto.name, '東京駅');
      expect(dto.latitude, 35.681236);
      expect(dto.longitude, 139.767125);
    });

    test('copyWithでnameをnullに更新できる', () {
      const dto = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      final copied = dto.copyWith(name: null);

      expect(copied.name, isNull);
      expect(copied.id, dto.id);
    });
  });
}
