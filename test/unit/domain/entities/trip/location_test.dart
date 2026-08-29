import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('Location', () {
    test('緯度または経度が数値として不正な場合は例外', () {
      expect(
        () => Location(
          id: 'location-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: double.nan,
          longitude: 139.767125,
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => Location(
          id: 'location-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.681236,
          longitude: double.infinity,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
