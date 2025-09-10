import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/notifiers/location_notifier.dart';
import 'package:memora/domain/services/current_location_service.dart';

import 'location_notifier_test.mocks.dart';

@GenerateNiceMocks([MockSpec<CurrentLocationService>()])
void main() {
  group('LocationNotifier', () {
    late LocationNotifier locationNotifier;
    late MockCurrentLocationService mockCurrentLocationService;

    setUp(() {
      mockCurrentLocationService = MockCurrentLocationService();
      locationNotifier = LocationNotifier(mockCurrentLocationService);
    });

    test('初期状態では位置情報がnullである', () {
      expect(locationNotifier.state.location, isNull);
      expect(locationNotifier.state.lastUpdated, isNull);
    });

    test('現在地取得成功時に状態が更新される', () async {
      final completer = Completer<Location?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final future = locationNotifier.getCurrentLocation();

      const expectedLocation = Location(latitude: 35.6812, longitude: 139.7671);
      completer.complete(expectedLocation);

      await future;

      expect(locationNotifier.state.location, expectedLocation);
      expect(locationNotifier.state.lastUpdated, isNotNull);
    });

    test('現在地取得失敗時でも状態が変更されない', () async {
      final completer = Completer<Location?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final future = locationNotifier.getCurrentLocation();

      completer.completeError(Exception('位置情報取得エラー'));

      await expectLater(future, throwsException);

      expect(locationNotifier.state.location, isNull);
      expect(locationNotifier.state.lastUpdated, isNull);
    });

    test('手動で位置情報を設定できる', () {
      locationNotifier.setLocation(
        Location(latitude: 35.6812, longitude: 139.7671),
      );

      expect(
        locationNotifier.state.location,
        Location(latitude: 35.6812, longitude: 139.7671),
      );
      expect(locationNotifier.state.lastUpdated, isNotNull);
    });

    test('位置情報をクリアできる', () {
      locationNotifier.setLocation(
        Location(latitude: 35.6812, longitude: 139.7671),
      );
      locationNotifier.clearLocation();

      expect(locationNotifier.state.location, isNull);
      expect(locationNotifier.state.lastUpdated, isNull);
    });
  });
}
