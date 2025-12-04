import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';

void main() {
  group('RouteDto', () {
    test('必須パラメータのみで生成できる', () {
      final dto = RouteDto(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.walk,
      );

      expect(dto.tripId, 'trip001');
      expect(dto.orderIndex, 0);
      expect(dto.departurePinId, 'pinA');
      expect(dto.arrivalPinId, 'pinB');
      expect(dto.travelMode, TravelMode.walk);
      expect(dto.distanceMeters, isNull);
      expect(dto.durationSeconds, isNull);
      expect(dto.instructions, isNull);
      expect(dto.polyline, isNull);
    });

    test('copyWithで任意の値を更新できる', () {
      final dto = RouteDto(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      final copied = dto.copyWith(
        orderIndex: 2,
        travelMode: TravelMode.other,
        distanceMeters: 2000,
        durationSeconds: 400,
        instructions: '左折',
        polyline: 'polylineData',
      );

      expect(copied.orderIndex, 2);
      expect(copied.travelMode, TravelMode.other);
      expect(copied.distanceMeters, 2000);
      expect(copied.durationSeconds, 400);
      expect(copied.instructions, '左折');
      expect(copied.polyline, 'polylineData');
    });

    test('同じ値を持つDtoは等価となる', () {
      final dto1 = RouteDto(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      final dto2 = RouteDto(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, dto2.hashCode);
    });

    test('異なる値を持つDtoは等価ではない', () {
      final dto1 = RouteDto(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      final dto2 = RouteDto(
        tripId: 'trip002',
        orderIndex: 1,
        departurePinId: 'pinB',
        arrivalPinId: 'pinC',
        travelMode: TravelMode.walk,
      );

      expect(dto1, isNot(equals(dto2)));
    });
  });
}
