import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/location_state.dart';

void main() {
  group('LocationState', () {
    test('緯度と経度を持つLocationStateを作成できる', () {
      const latitude = 35.6812;
      const longitude = 139.7671;
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState = LocationState(
        latitude: latitude,
        longitude: longitude,
        lastUpdated: lastUpdated,
      );

      expect(locationState.latitude, latitude);
      expect(locationState.longitude, longitude);
      expect(locationState.lastUpdated, lastUpdated);
    });

    test('copyWithで緯度を更新できる', () {
      final original = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: DateTime(2025, 1, 1),
      );

      const newLatitude = 35.6813;
      final updated = original.copyWith(latitude: newLatitude);

      expect(updated.latitude, newLatitude);
      expect(updated.longitude, original.longitude);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('copyWithで経度を更新できる', () {
      final original = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: DateTime(2025, 1, 1),
      );

      const newLongitude = 139.7672;
      final updated = original.copyWith(longitude: newLongitude);

      expect(updated.latitude, original.latitude);
      expect(updated.longitude, newLongitude);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('copyWithで最終更新日時を更新できる', () {
      final original = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: DateTime(2025, 1, 1),
      );

      final newLastUpdated = DateTime(2025, 1, 2);
      final updated = original.copyWith(lastUpdated: newLastUpdated);

      expect(updated.latitude, original.latitude);
      expect(updated.longitude, original.longitude);
      expect(updated.lastUpdated, newLastUpdated);
    });

    test('初期状態では全てのフィールドがnullである', () {
      const locationState = LocationState();

      expect(locationState.latitude, isNull);
      expect(locationState.longitude, isNull);
      expect(locationState.lastUpdated, isNull);
    });
  });
}
