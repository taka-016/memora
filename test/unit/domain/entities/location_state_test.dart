import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/value-objects/location_state.dart';

void main() {
  group('LocationState', () {
    test('緯度と経度を持つLocationStateを作成できる', () {
      const location = Location(latitude: 35.6812, longitude: 139.7671);
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState = LocationState(
        location: location,
        lastUpdated: lastUpdated,
      );

      expect(locationState.location, location);
      expect(locationState.lastUpdated, lastUpdated);
    });

    test('copyWithでlocationを更新できる', () {
      final original = LocationState(
        location: Location(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: DateTime(2025, 1, 1),
      );

      const newLocation = Location(latitude: 35.6813, longitude: 139.7671);
      final updated = original.copyWith(location: newLocation);

      expect(updated.location, newLocation);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('copyWithで最終更新日時を更新できる', () {
      final original = LocationState(
        location: Location(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final newLastUpdated = DateTime(2025, 1, 2);
      final updated = original.copyWith(lastUpdated: newLastUpdated);

      expect(updated.location, original.location);
      expect(updated.lastUpdated, newLastUpdated);
    });

    test('初期状態では全てのフィールドがnullである', () {
      const locationState = LocationState();

      expect(locationState.location, isNull);
      expect(locationState.lastUpdated, isNull);
    });

    test('同じlocationとlastUpdatedを持つLocationStateは等しい', () {
      const location = Location(latitude: 35.6812, longitude: 139.7671);
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState1 = LocationState(
        location: location,
        lastUpdated: lastUpdated,
      );
      final locationState2 = LocationState(
        location: location,
        lastUpdated: lastUpdated,
      );

      expect(locationState1, equals(locationState2));
      expect(locationState1.hashCode, equals(locationState2.hashCode));
    });

    test('異なるlocationを持つLocationStateは等しくない', () {
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState1 = LocationState(
        location: Location(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: lastUpdated,
      );
      final locationState2 = LocationState(
        location: Location(latitude: 35.6813, longitude: 139.7671),
        lastUpdated: lastUpdated,
      );

      expect(locationState1, isNot(equals(locationState2)));
    });

    test('異なるlastUpdatedを持つLocationStateは等しくない', () {
      const location = Location(latitude: 35.6812, longitude: 139.7671);

      final locationState1 = LocationState(
        location: location,
        lastUpdated: DateTime(2025, 1, 1),
      );
      final locationState2 = LocationState(
        location: location,
        lastUpdated: DateTime(2025, 1, 2),
      );

      expect(locationState1, isNot(equals(locationState2)));
    });

    test('nullフィールドを持つLocationStateの等価性', () {
      const locationState1 = LocationState();
      const locationState2 = LocationState();

      expect(locationState1, equals(locationState2));
      expect(locationState1.hashCode, equals(locationState2.hashCode));
    });
  });
}
