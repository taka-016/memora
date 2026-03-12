import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/models/coordinate.dart';
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

      expect(state.coordinate, isNull);
      expect(state.lastUpdated, isNull);
    });

    test('現在地取得成功時に状態が更新される', () async {
      final completer = Completer<Coordinate?>();
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) => completer.future);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      final future = notifier.getCurrentLocation();

      final expectedCoordinate = Coordinate(
        latitude: 35.6812,
        longitude: 139.7671,
      );
      completer.complete(expectedCoordinate);

      await future;

      final state = container.read(locationProvider);
      expect(state.coordinate, expectedCoordinate);
      expect(state.lastUpdated, isNotNull);
    });

    test('現在地取得失敗時でも状態が変更されない', () async {
      final completer = Completer<Coordinate?>();
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
      expect(state.coordinate, isNull);
      expect(state.lastUpdated, isNull);
    });

    test('手動で位置情報を設定できる', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.setCoordinate(
        Coordinate(latitude: 35.6812, longitude: 139.7671),
      );

      final state = container.read(locationProvider);
      expect(
        state.coordinate,
        Coordinate(latitude: 35.6812, longitude: 139.7671),
      );
      expect(state.lastUpdated, isNotNull);
    });

    test('位置情報をクリアできる', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.setCoordinate(
        Coordinate(latitude: 35.6812, longitude: 139.7671),
      );
      notifier.clearCoordinate();

      final state = container.read(locationProvider);
      expect(state.coordinate, isNull);
      expect(state.lastUpdated, isNull);
    });
  });
}
