import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/domain/entities/pin.dart';

Pin _createPin({
  String id = 'pin-id-123',
  String pinId = 'pin-123',
  String tripId = 'trip-456',
  String groupId = 'group-789',
  double latitude = 35.6762,
  double longitude = 139.6503,
  String? locationName,
  DateTime? visitStartDate,
  DateTime? visitEndDate,
  String? visitMemo,
}) {
  return Pin(
    id: id,
    pinId: pinId,
    tripId: tripId,
    groupId: groupId,
    latitude: latitude,
    longitude: longitude,
    locationName: locationName,
    visitStartDate: visitStartDate,
    visitEndDate: visitEndDate,
    visitMemo: visitMemo,
  );
}

PinDto _createPinDto({
  String? id = 'pin-id-123',
  String pinId = 'pin-123',
  String? tripId = 'trip-456',
  String? groupId = 'group-789',
  double latitude = 35.6762,
  double longitude = 139.6503,
  String? locationName,
  DateTime? visitStartDate,
  DateTime? visitEndDate,
  String? visitMemo,
}) {
  return PinDto(
    id: id,
    pinId: pinId,
    tripId: tripId,
    groupId: groupId,
    latitude: latitude,
    longitude: longitude,
    locationName: locationName,
    visitStartDate: visitStartDate,
    visitEndDate: visitEndDate,
    visitMemo: visitMemo,
  );
}

void main() {
  group('PinMapper', () {
    group('toDto', () {
      test('エンティティの全フィールドをDtoに写し替える', () {
        final pin = _createPin(
          locationName: '東京駅',
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
          visitMemo: '観光で訪問',
        );

        final dto = PinMapper.toDto(pin);

        expect(dto.id, 'pin-id-123');
        expect(dto.pinId, 'pin-123');
        expect(dto.tripId, 'trip-456');
        expect(dto.latitude, 35.6762);
        expect(dto.longitude, 139.6503);
        expect(dto.locationName, '東京駅');
        expect(dto.visitStartDate, DateTime(2024, 1, 1, 10, 0));
        expect(dto.visitEndDate, DateTime(2024, 1, 1, 12, 0));
        expect(dto.visitMemo, '観光で訪問');
      });

      test('groupIdはDtoへは引き継がれず常にnullになる', () {
        final pin = _createPin(groupId: 'group-unique');

        final dto = PinMapper.toDto(pin);

        expect(dto.groupId, isNull);
      });

      test('オプショナルフィールドがnullのエンティティでもそのままnullを保持する', () {
        final pin = _createPin();

        final dto = PinMapper.toDto(pin);

        expect(dto.locationName, isNull);
        expect(dto.visitStartDate, isNull);
        expect(dto.visitEndDate, isNull);
        expect(dto.visitMemo, isNull);
      });

      test('空文字のvisitMemoも保持される', () {
        final pin = _createPin(visitMemo: '');

        final dto = PinMapper.toDto(pin);

        expect(dto.visitMemo, '');
      });
    });

    group('toEntity', () {
      test('Dtoをエンティティに正しく変換する', () {
        final dto = _createPinDto(
          locationName: '東京駅',
          visitStartDate: DateTime(2024, 1, 1, 10, 0),
          visitEndDate: DateTime(2024, 1, 1, 12, 0),
          visitMemo: '観光で訪問',
        );

        final entity = PinMapper.toEntity(dto);

        expect(entity.id, 'pin-id-123');
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

      test('idがnullのDtoはエンティティで空文字になる', () {
        final dto = _createPinDto(id: null);

        final entity = PinMapper.toEntity(dto);

        expect(entity.id, '');
        expect(entity.pinId, 'pin-123');
      });

      test('オプショナルフィールドがnullのDtoでもnullのまま保持する', () {
        final dto = _createPinDto();

        final entity = PinMapper.toEntity(dto);

        expect(entity.locationName, isNull);
        expect(entity.visitStartDate, isNull);
        expect(entity.visitEndDate, isNull);
        expect(entity.visitMemo, isNull);
      });

      test('空文字のvisitMemoも保持される', () {
        final dto = _createPinDto(visitMemo: '');

        final entity = PinMapper.toEntity(dto);

        expect(entity.visitMemo, '');
      });

      test('tripIdやgroupIdがnullの場合は例外が発生する', () {
        final dto = _createPinDto(tripId: null, groupId: null);

        expect(() => PinMapper.toEntity(dto), throwsA(isA<TypeError>()));
      });
    });

    group('リスト変換', () {
      test('エンティティリストをDtoリストに変換する', () {
        final pins = [
          _createPin(
            id: 'pin-id-1',
            pinId: 'pin-1',
            tripId: 'trip-1',
            groupId: 'group-1',
            locationName: '東京駅',
          ),
          _createPin(
            id: 'pin-id-2',
            pinId: 'pin-2',
            tripId: 'trip-2',
            groupId: 'group-2',
            locationName: '大阪駅',
          ),
        ];

        final dtos = PinMapper.toDtoList(pins);

        expect(dtos, hasLength(2));
        expect(dtos[0].id, 'pin-id-1');
        expect(dtos[0].tripId, 'trip-1');
        expect(dtos[0].locationName, '東京駅');
        expect(dtos[1].id, 'pin-id-2');
        expect(dtos[1].tripId, 'trip-2');
        expect(dtos[1].locationName, '大阪駅');
      });

      test('Dtoリストをエンティティリストに変換する', () {
        final dtos = [
          _createPinDto(
            id: 'pin-id-1',
            pinId: 'pin-1',
            tripId: 'trip-1',
            groupId: 'group-1',
            locationName: '東京駅',
          ),
          _createPinDto(
            id: 'pin-id-2',
            pinId: 'pin-2',
            tripId: 'trip-2',
            groupId: 'group-2',
            locationName: '大阪駅',
          ),
        ];

        final entities = PinMapper.toEntityList(dtos);

        expect(entities, hasLength(2));
        expect(entities[0].id, 'pin-id-1');
        expect(entities[0].groupId, 'group-1');
        expect(entities[0].locationName, '東京駅');
        expect(entities[1].id, 'pin-id-2');
        expect(entities[1].groupId, 'group-2');
        expect(entities[1].locationName, '大阪駅');
      });

      test('空のリストはそのまま空のまま変換される', () {
        expect(PinMapper.toDtoList(const <Pin>[]), isEmpty);
        expect(PinMapper.toEntityList(const <PinDto>[]), isEmpty);
      });
    });
  });
}
