import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/value_objects/location.dart';

void main() {
  group('Location', () {
    test('正常な緯度経度で Location を作成できる', () {
      // Arrange
      const latitude = 35.6762;
      const longitude = 139.6503;

      // Act
      final location = Location(latitude: latitude, longitude: longitude);

      // Assert
      expect(location.latitude, latitude);
      expect(location.longitude, longitude);
    });

    test('同じ緯度経度の Location は等価である', () {
      // Arrange
      final location1 = Location(latitude: 35.6762, longitude: 139.6503);
      final location2 = Location(latitude: 35.6762, longitude: 139.6503);

      // Act & Assert
      expect(location1, equals(location2));
      expect(location1.hashCode, equals(location2.hashCode));
    });

    test('異なる緯度経度の Location は等価でない', () {
      // Arrange
      final location1 = Location(latitude: 35.6762, longitude: 139.6503);
      final location2 = Location(latitude: 35.6763, longitude: 139.6503);

      // Act & Assert
      expect(location1, isNot(equals(location2)));
    });

    test('props は latitude と longitude を返す', () {
      // Arrange
      const latitude = 35.6762;
      const longitude = 139.6503;
      final location = Location(latitude: latitude, longitude: longitude);

      // Act
      final props = location.props;

      // Assert
      expect(props, [latitude, longitude]);
    });

    test('極値での Location 作成', () {
      // Arrange & Act
      final northPole = Location(latitude: 90.0, longitude: 0.0);
      final southPole = Location(latitude: -90.0, longitude: 0.0);
      final eastMost = Location(latitude: 0.0, longitude: 180.0);
      final westMost = Location(latitude: 0.0, longitude: -180.0);

      // Assert
      expect(northPole.latitude, 90.0);
      expect(southPole.latitude, -90.0);
      expect(eastMost.longitude, 180.0);
      expect(westMost.longitude, -180.0);
    });

    test('緯度が-90未満または90超過の場合は例外が発生する', () {
      expect(
        () => Location(latitude: -90.0001, longitude: 139.6503),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => Location(latitude: 90.0001, longitude: 139.6503),
        throwsA(isA<ValidationException>()),
      );
    });

    test('経度が-180未満または180超過の場合は例外が発生する', () {
      expect(
        () => Location(latitude: 35.6762, longitude: -180.0001),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => Location(latitude: 35.6762, longitude: 180.0001),
        throwsA(isA<ValidationException>()),
      );
    });

    test('緯度または経度が非有限値の場合は例外が発生する', () {
      expect(
        () => Location(latitude: double.nan, longitude: 139.6503),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => Location(latitude: 35.6762, longitude: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
