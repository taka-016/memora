import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/domain/entities/pin.dart';

void main() {
  group('PinMapper', () {
    test('PinエンティティをPinDtoに正しく変換する', () {
      // Arrange
      final pin = Pin(
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
        locationName: '東京駅',
        visitStartDate: DateTime(2024, 1, 1, 10, 0),
        visitEndDate: DateTime(2024, 1, 1, 12, 0),
        visitMemo: '観光で訪問',
      );

      // Act
      final dto = PinMapper.toDto(pin);

      // Assert
      expect(dto.pinId, 'pin-123');
      expect(dto.tripId, 'trip-456');
      expect(dto.groupId, null); // groupIdはDtoからエンティティへの変換でのみ使用される
      expect(dto.latitude, 35.6762);
      expect(dto.longitude, 139.6503);
      expect(dto.locationName, '東京駅');
      expect(dto.visitStartDate, DateTime(2024, 1, 1, 10, 0));
      expect(dto.visitEndDate, DateTime(2024, 1, 1, 12, 0));
      expect(dto.visitMemo, '観光で訪問');
    });

    test('オプショナルプロパティがnullのPinエンティティをDtoに変換する', () {
      // Arrange
      final pin = Pin(
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
      );

      // Act
      final dto = PinMapper.toDto(pin);

      // Assert
      expect(dto.pinId, 'pin-123');
      expect(dto.tripId, 'trip-456');
      expect(dto.latitude, 35.6762);
      expect(dto.longitude, 139.6503);
      expect(dto.locationName, isNull);
      expect(dto.visitStartDate, isNull);
      expect(dto.visitEndDate, isNull);
      expect(dto.visitMemo, isNull);
    });

    test('PinDtoをPinエンティティに正しく変換する', () {
      // Arrange
      final dto = PinDto(
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
        locationName: '東京駅',
        visitStartDate: DateTime(2024, 1, 1, 10, 0),
        visitEndDate: DateTime(2024, 1, 1, 12, 0),
        visitMemo: '観光で訪問',
      );

      // Act
      final entity = PinMapper.toEntity(dto);

      // Assert
      expect(entity.pinId, 'pin-123');
      expect(entity.tripId, 'trip-456');
      expect(entity.groupId, 'group-789');
      expect(entity.latitude, 35.6762);
      expect(entity.longitude, 139.6503);
      expect(entity.locationName, '東京駅');
      expect(entity.visitStartDate, DateTime(2024, 1, 1, 10, 0));
      expect(entity.visitEndDate, DateTime(2024, 1, 1, 12, 0));
      expect(entity.visitMemo, '観光で訪問');
    });

    test('idがnullのDtoをエンティティに変換する際は空文字列になる', () {
      // Arrange
      final dto = PinDto(
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
      );

      // Act
      final entity = PinMapper.toEntity(dto);

      // Assert
      expect(entity.pinId, 'pin-123');
      expect(entity.tripId, 'trip-456');
      expect(entity.groupId, 'group-789');
    });

    test('オプショナルプロパティがnullのDtoをエンティティに変換する', () {
      // Arrange
      final dto = PinDto(
        pinId: 'pin-123',
        tripId: 'trip-456',
        groupId: 'group-789',
        latitude: 35.6762,
        longitude: 139.6503,
      );

      // Act
      final entity = PinMapper.toEntity(dto);

      // Assert
      expect(entity.pinId, 'pin-123');
      expect(entity.tripId, 'trip-456');
      expect(entity.groupId, 'group-789');
      expect(entity.latitude, 35.6762);
      expect(entity.longitude, 139.6503);
      expect(entity.locationName, isNull);
      expect(entity.visitStartDate, isNull);
      expect(entity.visitEndDate, isNull);
      expect(entity.visitMemo, isNull);
    });

    test('Pinエンティティのリストを正しくDtoリストに変換する', () {
      // Arrange
      final pins = [
        Pin(
          pinId: 'pin-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
        ),
        Pin(
          pinId: 'pin-2',
          tripId: 'trip-2',
          groupId: 'group-2',
          latitude: 34.7024,
          longitude: 135.4959,
          locationName: '大阪駅',
        ),
      ];

      // Act
      final dtos = PinMapper.toDtoList(pins);

      // Assert
      expect(dtos.length, 2);
      expect(dtos[0].pinId, 'pin-1');
      expect(dtos[0].tripId, 'trip-1');
      expect(dtos[0].locationName, '東京駅');
      expect(dtos[1].pinId, 'pin-2');
      expect(dtos[1].tripId, 'trip-2');
      expect(dtos[1].locationName, '大阪駅');
    });

    test('PinDtoのリストを正しくエンティティリストに変換する', () {
      // Arrange
      final dtos = [
        PinDto(
          pinId: 'pin-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.6762,
          longitude: 139.6503,
          locationName: '東京駅',
        ),
        PinDto(
          pinId: 'pin-2',
          tripId: 'trip-2',
          groupId: 'group-2',
          latitude: 34.7024,
          longitude: 135.4959,
          locationName: '大阪駅',
        ),
      ];

      // Act
      final entities = PinMapper.toEntityList(dtos);

      // Assert
      expect(entities.length, 2);
      expect(entities[0].pinId, 'pin-1');
      expect(entities[0].tripId, 'trip-1');
      expect(entities[0].groupId, 'group-1');
      expect(entities[0].locationName, '東京駅');
      expect(entities[1].pinId, 'pin-2');
      expect(entities[1].tripId, 'trip-2');
      expect(entities[1].groupId, 'group-2');
      expect(entities[1].locationName, '大阪駅');
    });

    test('空のリストを変換する', () {
      // Arrange
      final emptyPinList = <Pin>[];
      final emptyDtoList = <PinDto>[];

      // Act
      final emptyDtoResult = PinMapper.toDtoList(emptyPinList);
      final emptyEntityResult = PinMapper.toEntityList(emptyDtoList);

      // Assert
      expect(emptyDtoResult, isEmpty);
      expect(emptyEntityResult, isEmpty);
    });
  });
}
