import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/models/coordinate.dart';

void main() {
  group('Coordinate', () {
    test('緯度経度を保持できる', () {
      const latitude = 35.6762;
      const longitude = 139.6503;

      const coordinate = Coordinate(latitude: latitude, longitude: longitude);

      expect(coordinate.latitude, latitude);
      expect(coordinate.longitude, longitude);
    });

    test('同じ緯度経度の Coordinate は等価である', () {
      const coordinate1 = Coordinate(latitude: 35.6762, longitude: 139.6503);
      const coordinate2 = Coordinate(latitude: 35.6762, longitude: 139.6503);

      expect(coordinate1, equals(coordinate2));
      expect(coordinate1.hashCode, equals(coordinate2.hashCode));
    });

    test('異なる緯度経度の Coordinate は等価でない', () {
      const coordinate1 = Coordinate(latitude: 35.6762, longitude: 139.6503);
      const coordinate2 = Coordinate(latitude: 35.6763, longitude: 139.6503);

      expect(coordinate1, isNot(equals(coordinate2)));
    });

    test('props は latitude と longitude を返す', () {
      const coordinate = Coordinate(latitude: 35.6762, longitude: 139.6503);

      expect(coordinate.props, [35.6762, 139.6503]);
    });

    test('範囲外や非有限値もそのまま保持する', () {
      const invalidLatitude = 120.5;
      const invalidLongitude = double.infinity;

      const coordinate = Coordinate(
        latitude: invalidLatitude,
        longitude: invalidLongitude,
      );

      expect(coordinate.latitude, invalidLatitude);
      expect(coordinate.longitude, invalidLongitude);
    });
  });
}
