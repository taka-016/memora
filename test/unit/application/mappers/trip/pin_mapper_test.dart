import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';

void main() {
  group('PinMapper', () {
    test('PinDtoをPinエンティティに変換できる', () {
      final visitStartDate = DateTime(2026, 4, 1, 9, 0);
      final visitEndDate = DateTime(2026, 4, 1, 11, 30);
      final dto = PinDto(
        pinId: 'pin-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        latitude: 35.0,
        longitude: 135.0,
        locationName: '大阪',
        visitStartDate: visitStartDate,
        visitEndDate: visitEndDate,
        visitMemo: '朝一で訪問',
      );

      final entity = PinMapper.toEntity(dto);

      expect(entity.pinId, 'pin-1');
      expect(entity.tripId, 'trip-1');
      expect(entity.groupId, 'group-1');
      expect(entity.latitude, 35.0);
      expect(entity.longitude, 135.0);
      expect(entity.locationName, '大阪');
      expect(entity.visitStartDate, visitStartDate);
      expect(entity.visitEndDate, visitEndDate);
      expect(entity.visitMemo, '朝一で訪問');
    });

    test('tripIdとgroupIdがnullの場合は空文字に変換される', () {
      final dto = PinDto(
        pinId: 'pin-2',
        tripId: null,
        groupId: null,
        latitude: 34.0,
        longitude: 135.0,
      );

      final entity = PinMapper.toEntity(dto);

      expect(entity.pinId, 'pin-2');
      expect(entity.tripId, '');
      expect(entity.groupId, '');
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
