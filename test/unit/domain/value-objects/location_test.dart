import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value-objects/location.dart';

void main() {
  group('Location', () {
    test('正常な緯度経度で Location を作成できる', () {
      // Arrange
      const latitude = 35.6762;
      const longitude = 139.6503;

      // Act
      const location = Location(latitude: latitude, longitude: longitude);

      // Assert
      expect(location.latitude, latitude);
      expect(location.longitude, longitude);
    });

    test('同じ緯度経度の Location は等価である', () {
      // Arrange
      const location1 = Location(latitude: 35.6762, longitude: 139.6503);
      const location2 = Location(latitude: 35.6762, longitude: 139.6503);

      // Act & Assert
      expect(location1, equals(location2));
      expect(location1.hashCode, equals(location2.hashCode));
    });

    test('異なる緯度経度の Location は等価でない', () {
      // Arrange
      const location1 = Location(latitude: 35.6762, longitude: 139.6503);
      const location2 = Location(latitude: 35.6763, longitude: 139.6503);

      // Act & Assert
      expect(location1, isNot(equals(location2)));
    });

    test('props は latitude と longitude を返す', () {
      // Arrange
      const latitude = 35.6762;
      const longitude = 139.6503;
      const location = Location(latitude: latitude, longitude: longitude);

      // Act
      final props = location.props;

      // Assert
      expect(props, [latitude, longitude]);
    });

    test('極値での Location 作成', () {
      // Arrange & Act
      const northPole = Location(latitude: 90.0, longitude: 0.0);
      const southPole = Location(latitude: -90.0, longitude: 0.0);
      const eastMost = Location(latitude: 0.0, longitude: 180.0);
      const westMost = Location(latitude: 0.0, longitude: -180.0);

      // Assert
      expect(northPole.latitude, 90.0);
      expect(southPole.latitude, -90.0);
      expect(eastMost.longitude, 180.0);
      expect(westMost.longitude, -180.0);
    });
  });
}
