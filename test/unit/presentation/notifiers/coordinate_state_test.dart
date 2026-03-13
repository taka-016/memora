import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/notifiers/coordinate_state.dart';

void main() {
  group('CoordinateState', () {
    test('緯度と経度を持つCoordinateStateを作成できる', () {
      final coordinate = Coordinate(latitude: 35.6812, longitude: 139.7671);
      final lastUpdated = DateTime(2025, 1, 1);

      final coordinateState = CoordinateState(
        coordinate: coordinate,
        lastUpdated: lastUpdated,
      );

      expect(coordinateState.coordinate, coordinate);
      expect(coordinateState.lastUpdated, lastUpdated);
    });

    test('copyWithでcoordinateを更新できる', () {
      final original = CoordinateState(
        coordinate: Coordinate(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final newCoordinate = Coordinate(latitude: 35.6813, longitude: 139.7671);
      final updated = original.copyWith(coordinate: newCoordinate);

      expect(updated.coordinate, newCoordinate);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('copyWithで最終更新日時を更新できる', () {
      final original = CoordinateState(
        coordinate: Coordinate(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final newLastUpdated = DateTime(2025, 1, 2);
      final updated = original.copyWith(lastUpdated: newLastUpdated);

      expect(updated.coordinate, original.coordinate);
      expect(updated.lastUpdated, newLastUpdated);
    });

    test('初期状態では全てのフィールドがnullである', () {
      const coordinateState = CoordinateState();

      expect(coordinateState.coordinate, isNull);
      expect(coordinateState.lastUpdated, isNull);
    });

    test('同じcoordinateとlastUpdatedを持つCoordinateStateは等しい', () {
      final coordinate = Coordinate(latitude: 35.6812, longitude: 139.7671);
      final lastUpdated = DateTime(2025, 1, 1);

      final coordinateState1 = CoordinateState(
        coordinate: coordinate,
        lastUpdated: lastUpdated,
      );
      final coordinateState2 = CoordinateState(
        coordinate: coordinate,
        lastUpdated: lastUpdated,
      );

      expect(coordinateState1, equals(coordinateState2));
      expect(coordinateState1.hashCode, equals(coordinateState2.hashCode));
    });

    test('異なるcoordinateを持つCoordinateStateは等しくない', () {
      final lastUpdated = DateTime(2025, 1, 1);

      final coordinateState1 = CoordinateState(
        coordinate: Coordinate(latitude: 35.6812, longitude: 139.7671),
        lastUpdated: lastUpdated,
      );
      final coordinateState2 = CoordinateState(
        coordinate: Coordinate(latitude: 35.6813, longitude: 139.7671),
        lastUpdated: lastUpdated,
      );

      expect(coordinateState1, isNot(equals(coordinateState2)));
    });

    test('異なるlastUpdatedを持つCoordinateStateは等しくない', () {
      final coordinate = Coordinate(latitude: 35.6812, longitude: 139.7671);

      final coordinateState1 = CoordinateState(
        coordinate: coordinate,
        lastUpdated: DateTime(2025, 1, 1),
      );
      final coordinateState2 = CoordinateState(
        coordinate: coordinate,
        lastUpdated: DateTime(2025, 1, 2),
      );

      expect(coordinateState1, isNot(equals(coordinateState2)));
    });

    test('nullフィールドを持つCoordinateStateの等価性', () {
      const coordinateState1 = CoordinateState();
      const coordinateState2 = CoordinateState();

      expect(coordinateState1, equals(coordinateState2));
      expect(coordinateState1.hashCode, equals(coordinateState2.hashCode));
    });
  });
}
