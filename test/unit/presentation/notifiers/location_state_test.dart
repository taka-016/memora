import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/notifiers/location_state.dart';

void main() {
  group('LocationState', () {
    test('緯度と経度を持つLocationStateを作成できる', () {
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: lastUpdated,
      );

      expect(locationState.latitude, 35.6812);
      expect(locationState.longitude, 139.7671);
      expect(locationState.lastUpdated, lastUpdated);
    });

    test('copyWithで位置情報を更新できる', () {
      final original = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(latitude: 35.6813, longitude: 139.7672);

      expect(updated.latitude, 35.6813);
      expect(updated.longitude, 139.7672);
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

    test('同じ位置情報とlastUpdatedを持つLocationStateは等しい', () {
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState1 = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: lastUpdated,
      );
      final locationState2 = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: lastUpdated,
      );

      expect(locationState1, equals(locationState2));
      expect(locationState1.hashCode, equals(locationState2.hashCode));
    });

    test('異なる位置情報を持つLocationStateは等しくない', () {
      final lastUpdated = DateTime(2025, 1, 1);

      final locationState1 = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: lastUpdated,
      );
      final locationState2 = LocationState(
        latitude: 35.6813,
        longitude: 139.7671,
        lastUpdated: lastUpdated,
      );

      expect(locationState1, isNot(equals(locationState2)));
    });

    test('異なるlastUpdatedを持つLocationStateは等しくない', () {
      final locationState1 = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
        lastUpdated: DateTime(2025, 1, 1),
      );
      final locationState2 = LocationState(
        latitude: 35.6812,
        longitude: 139.7671,
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
