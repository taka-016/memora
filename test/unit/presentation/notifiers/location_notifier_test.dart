import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/notifiers/location_notifier.dart';
import 'package:memora/domain/services/current_location_service.dart';
import '../../../helpers/test_exception.dart';

import 'location_notifier_test.mocks.dart';

@GenerateNiceMocks([MockSpec<CurrentLocationService>()])
void main() {
  group('LocationNotifier', () {
    late MockCurrentLocationService mockCurrentLocationService;

    setUp(() {
      mockCurrentLocationService = MockCurrentLocationService();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          currentLocationServiceProvider.overrideWithValue(
            mockCurrentLocationService,
          ),
        ],
      );
    }

    test('初期状態では位置情報がnullである', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(locationProvider);

      expect(state.location, isNull);
      expect(state.lastUpdated, isNull);
    });

    test('現在地取得成功時に状態が更新される', () async {
      final completer = Completer<Location?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      final future = notifier.getCurrentLocation();

      const expectedLocation = Location(latitude: 35.6812, longitude: 139.7671);
      completer.complete(expectedLocation);

      await future;

      final state = container.read(locationProvider);
      expect(state.location, expectedLocation);
      expect(state.lastUpdated, isNotNull);
    });

    test('現在地取得失敗時でも状態が変更されない', () async {
      final completer = Completer<Location?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      final future = notifier.getCurrentLocation();

      completer.completeError(TestException('位置情報取得エラー'));

      await expectLater(future, throwsException);

      final state = container.read(locationProvider);
      expect(state.location, isNull);
      expect(state.lastUpdated, isNull);
    });

    test('手動で位置情報を設定できる', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.setLocation(Location(latitude: 35.6812, longitude: 139.7671));

      final state = container.read(locationProvider);
      expect(state.location, Location(latitude: 35.6812, longitude: 139.7671));
      expect(state.lastUpdated, isNotNull);
    });

    test('位置情報をクリアできる', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.setLocation(Location(latitude: 35.6812, longitude: 139.7671));
      notifier.clearLocation();

      final state = container.read(locationProvider);
      expect(state.location, isNull);
      expect(state.lastUpdated, isNull);
    });
  });
}
