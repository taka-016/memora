import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';

void main() {
  group('TripEntryDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'trip-entry-123';
      const groupId = 'group-456';
      final tripStartDate = DateTime(2024, 5, 1);
      final tripEndDate = DateTime(2024, 5, 3);

      // Act
      final dto = TripEntryDto(
        id: id,
        groupId: groupId,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.groupId, groupId);
      expect(dto.tripName, isNull);
      expect(dto.tripStartDate, tripStartDate);
      expect(dto.tripEndDate, tripEndDate);
      expect(dto.tripMemo, isNull);
      expect(dto.pins, isNull);
      expect(dto.routes, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'trip-entry-123';
      const groupId = 'group-456';
      const tripName = '春の旅行';
      final tripStartDate = DateTime(2024, 5, 1);
      final tripEndDate = DateTime(2024, 5, 3);
      const tripMemo = '家族旅行のメモ';
      final pins = [
        PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0),
        PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0),
      ];
      final routes = [
        RouteDto(
          id: 'route-1',
          tripId: id,
          orderIndex: 0,
          departurePinId: 'pin-1',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
      ];

      // Act
      final dto = TripEntryDto(
        id: id,
        groupId: groupId,
        tripName: tripName,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
        tripMemo: tripMemo,
        pins: pins,
        routes: routes,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.groupId, groupId);
      expect(dto.tripName, tripName);
      expect(dto.tripStartDate, tripStartDate);
      expect(dto.tripEndDate, tripEndDate);
      expect(dto.tripMemo, tripMemo);
      expect(dto.pins, pins);
      expect(dto.pins!.length, 2);
      expect(dto.pins![0].pinId, 'pin-1');
      expect(dto.routes, routes);
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
      );

      // Act
      final copiedDto = originalDto.copyWith(
        id: 'trip-entry-999',
        groupId: 'group-888',
        tripStartDate: DateTime(2024, 6, 1),
        tripEndDate: DateTime(2024, 6, 3),
      );

      // Assert
      expect(copiedDto.id, 'trip-entry-999');
      expect(copiedDto.groupId, 'group-888');
      expect(copiedDto.tripStartDate, DateTime(2024, 6, 1));
      expect(copiedDto.tripEndDate, DateTime(2024, 6, 3));
      expect(copiedDto.tripName, isNull);
      expect(copiedDto.tripMemo, isNull);
      expect(copiedDto.pins, isNull);
      expect(copiedDto.routes, isNull);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripName: '元の旅行名',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: '元のメモ',
        pins: [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)],
        routes: [
          RouteDto(
            id: 'route-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            departurePinId: 'pin-1',
            arrivalPinId: 'pin-1b',
            travelMode: TravelMode.walk,
          ),
        ],
      );

      // Act
      final newPins = [
        PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0),
      ];
      final newRoutes = [
        RouteDto(
          id: 'route-2',
          tripId: 'trip-entry-123',
          orderIndex: 1,
          departurePinId: 'pin-1b',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
      ];
      final copiedDto = originalDto.copyWith(
        tripName: '新しい旅行名',
        tripMemo: '新しいメモ',
        pins: newPins,
        routes: newRoutes,
      );

      // Assert
      expect(copiedDto.id, 'trip-entry-123');
      expect(copiedDto.groupId, 'group-456');
      expect(copiedDto.tripName, '新しい旅行名');
      expect(copiedDto.tripMemo, '新しいメモ');
      expect(copiedDto.pins, newPins);
      expect(copiedDto.pins!.length, 1);
      expect(copiedDto.pins![0].pinId, 'pin-2');
      expect(copiedDto.routes, newRoutes);
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final pins = [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)];
      final routes = [
        RouteDto(
          id: 'route-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          departurePinId: 'pin-1',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
      ];
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripName: '旅行名',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: '旅行のメモ',
        pins: pins,
        routes: routes,
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'trip-entry-123');
      expect(copiedDto.groupId, 'group-456');
      expect(copiedDto.tripName, '旅行名');
      expect(copiedDto.tripStartDate, DateTime(2024, 5, 1));
      expect(copiedDto.tripEndDate, DateTime(2024, 5, 3));
      expect(copiedDto.tripMemo, '旅行のメモ');
      expect(copiedDto.pins, pins);
      expect(copiedDto.routes, routes);
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'trip-entry-123';
      const groupId = 'group-456';
      const tripName = '春の旅行';
      final tripStartDate = DateTime(2024, 5, 1);
      final tripEndDate = DateTime(2024, 5, 3);
      const tripMemo = '家族旅行のメモ';
      final pins = [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)];
      final routes = [
        RouteDto(
          id: 'route-1',
          tripId: id,
          orderIndex: 0,
          departurePinId: 'pin-1',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
      ];

      final dto1 = TripEntryDto(
        id: id,
        groupId: groupId,
        tripName: tripName,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
        tripMemo: tripMemo,
        pins: pins,
        routes: routes,
      );

      final dto2 = TripEntryDto(
        id: id,
        groupId: groupId,
        tripName: tripName,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
        tripMemo: tripMemo,
        pins: pins,
        routes: routes,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripName: '旅行A',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: 'メモA',
        pins: [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)],
        routes: [
          RouteDto(
            id: 'route-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            departurePinId: 'pin-1',
            arrivalPinId: 'pin-2',
            travelMode: TravelMode.drive,
          ),
        ],
      );

      final dto2 = TripEntryDto(
        id: 'trip-entry-999',
        groupId: 'group-888',
        tripName: '旅行B',
        tripStartDate: DateTime(2024, 6, 1),
        tripEndDate: DateTime(2024, 6, 3),
        tripMemo: 'メモB',
        pins: [PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0)],
        routes: [
          RouteDto(
            id: 'route-2',
            tripId: 'trip-entry-999',
            orderIndex: 0,
            departurePinId: 'pin-2',
            arrivalPinId: 'pin-3',
            travelMode: TravelMode.walk,
          ),
        ],
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
