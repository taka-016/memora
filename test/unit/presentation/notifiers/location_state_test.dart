import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/notifiers/location_state.dart';

void main() {
  group('LocationState', () {
    test('緯度と経度を持つLocationStateを作成できる', () {
      final coordinate = Coordinate(latitude: 35.6812, longitude: 139.7671);
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState = LocationState(
        coordinate: coordinate,
        lastUpdated: lastUpdated,
      );

      expect(locationState.coordinate, coordinate);
      expect(locationState.lastUpdated, lastUpdated);
    });

    test('copyWithでcoordinateを更新できる', () {
      final original = LocationState(
        coordinate: Coordinate(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final newCoordinate = Coordinate(latitude: 35.6813, longitude: 139.7671);
      final updated = original.copyWith(coordinate: newCoordinate);

      expect(updated.coordinate, newCoordinate);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('copyWithで最終更新日時を更新できる', () {
      final original = LocationState(
        coordinate: Coordinate(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final newLastUpdated = DateTime(2025, 1, 2);
      final updated = original.copyWith(lastUpdated: newLastUpdated);

      expect(updated.coordinate, original.coordinate);
      expect(updated.lastUpdated, newLastUpdated);
    });

    test('初期状態では全てのフィールドがnullである', () {
      const locationState = LocationState();

      expect(locationState.coordinate, isNull);
      expect(locationState.lastUpdated, isNull);
    });

    test('同じcoordinateとlastUpdatedを持つLocationStateは等しい', () {
      final coordinate = Coordinate(latitude: 35.6812, longitude: 139.7671);
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState1 = LocationState(
        coordinate: coordinate,
        lastUpdated: lastUpdated,
      );
      final locationState2 = LocationState(
        coordinate: coordinate,
        lastUpdated: lastUpdated,
      );

      expect(locationState1, equals(locationState2));
      expect(locationState1.hashCode, equals(locationState2.hashCode));
    });

    test('異なるcoordinateを持つLocationStateは等しくない', () {
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState1 = LocationState(
        coordinate: Coordinate(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: lastUpdated,
      );
      final locationState2 = LocationState(
        coordinate: Coordinate(latitude: 35.6813, longitude: 139.7671),
        lastUpdated: lastUpdated,
      );

      expect(locationState1, isNot(equals(locationState2)));
    });

    test('異なるlastUpdatedを持つLocationStateは等しくない', () {
      final coordinate = Coordinate(latitude: 35.6812, longitude: 139.7671);

      final locationState1 = LocationState(
        coordinate: coordinate,
        lastUpdated: DateTime(2025, 1, 1),
      );
      final locationState2 = LocationState(
        coordinate: coordinate,
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
