import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('Route', () {
    test('必須パラメータでインスタンス化できる', () {
      final route = Route(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
      );

      expect(route.tripId, 'trip001');
      expect(route.orderIndex, 0);
      expect(route.departurePinId, 'pinA');
      expect(route.arrivalPinId, 'pinB');
      expect(route.travelMode, TravelMode.drive);
      expect(route.distanceMeters, isNull);
      expect(route.durationSeconds, isNull);
      expect(route.instructions, isNull);
      expect(route.polyline, isNull);
    });

    test('orderIndexが負の場合はValidationExceptionを投げる', () {
      expect(
        () => Route(
          tripId: 'trip001',
          orderIndex: -1,
          departurePinId: 'pinA',
          arrivalPinId: 'pinB',
          travelMode: TravelMode.walk,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('距離または時間が負の場合はValidationExceptionを投げる', () {
      expect(
        () => Route(
          tripId: 'trip001',
          orderIndex: 0,
          departurePinId: 'pinA',
          arrivalPinId: 'pinB',
          travelMode: TravelMode.drive,
          distanceMeters: -10,
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => Route(
          tripId: 'trip001',
          orderIndex: 0,
          departurePinId: 'pinA',
          arrivalPinId: 'pinB',
          travelMode: TravelMode.drive,
          durationSeconds: -5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('出発Pinと到着Pinが同じ場合はValidationExceptionを投げる', () {
      expect(
        () => Route(
          tripId: 'trip001',
          orderIndex: 0,
          departurePinId: 'pinA',
          arrivalPinId: 'pinA',
          travelMode: TravelMode.drive,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('copyWithで値を更新できる', () {
      final route = Route(
        tripId: 'trip001',
        orderIndex: 0,
        departurePinId: 'pinA',
        arrivalPinId: 'pinB',
        travelMode: TravelMode.drive,
        distanceMeters: 1200,
        durationSeconds: 300,
        instructions: 'まっすぐ進む',
        polyline: 'encodedPolyline',
      );

      final updated = route.copyWith(
        orderIndex: 1,
        travelMode: TravelMode.walk,
        distanceMeters: 1500,
        durationSeconds: 360,
        instructions: '右折',
        polyline: 'newPolyline',
      );

      expect(updated.orderIndex, 1);
      expect(updated.travelMode, TravelMode.walk);
      expect(updated.distanceMeters, 1500);
      expect(updated.durationSeconds, 360);
      expect(updated.instructions, '右折');
      expect(updated.polyline, 'newPolyline');
      expect(updated.tripId, 'trip001');
      expect(updated.departurePinId, 'pinA');
      expect(updated.arrivalPinId, 'pinB');
    });
  });
}
