import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/managers/location_manager.dart';
import 'package:memora/domain/services/current_location_service.dart';

import 'location_manager_test.mocks.dart';

@GenerateNiceMocks([MockSpec<CurrentLocationService>()])
void main() {
  group('LocationManager', () {
    late LocationManager locationManager;
    late MockCurrentLocationService mockCurrentLocationService;

    setUp(() {
      mockCurrentLocationService = MockCurrentLocationService();
      locationManager = LocationManager(mockCurrentLocationService);
    });

    test('初期状態では位置情報がnullである', () {
      expect(locationManager.state.location, isNull);
      expect(locationManager.state.lastUpdated, isNull);
    });

    test('現在地取得成功時に状態が更新される', () async {
      final completer = Completer<Location?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final future = locationManager.getCurrentLocation();

      const expectedLocation = Location(latitude: 35.6812, longitude: 139.7671);
      completer.complete(expectedLocation);

      await future;

      expect(locationManager.state.location, expectedLocation);
      expect(locationManager.state.lastUpdated, isNotNull);
    });

    test('現在地取得失敗時でも状態が変更されない', () async {
      final completer = Completer<Location?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final future = locationManager.getCurrentLocation();

      completer.completeError(Exception('位置情報取得エラー'));

      await expectLater(future, throwsException);

      expect(locationManager.state.location, isNull);
      expect(locationManager.state.lastUpdated, isNull);
    });

    test('手動で位置情報を設定できる', () {
      locationManager.setLocation(
        Location(latitude: 35.6812, longitude: 139.7671),
      );

      expect(
        locationManager.state.location,
        Location(latitude: 35.6812, longitude: 139.7671),
      );
      expect(locationManager.state.lastUpdated, isNotNull);
    });

    test('位置情報をクリアできる', () {
      locationManager.setLocation(
        Location(latitude: 35.6812, longitude: 139.7671),
      );
      locationManager.clearLocation();

      expect(locationManager.state.location, isNull);
      expect(locationManager.state.lastUpdated, isNull);
    });
  });
}
