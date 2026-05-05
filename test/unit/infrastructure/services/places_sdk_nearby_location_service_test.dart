import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/infrastructure/services/places_sdk_nearby_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('memora/places');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PlacesSdkNearbyLocationService', () {
    test('位置情報をNearby Searchへ渡して場所名を返す', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            capturedCall = call;
            return '東京タワー';
          });

      final service = PlacesSdkNearbyLocationService(channel: channel);

      final result = await service.getLocationName(
        const Coordinate(latitude: 35.6586, longitude: 139.7454),
      );

      expect(capturedCall?.method, 'searchNearby');
      expect(capturedCall?.arguments, {
        'latitude': 35.6586,
        'longitude': 139.7454,
        'radiusMeters': 50.0,
        'maxResultCount': 1,
      });
      expect(result, '東京タワー');
    });

    test('Nearby Searchが失敗した場合はnullを返す', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            throw PlatformException(code: 'PLACES_ERROR');
          });

      final service = PlacesSdkNearbyLocationService(channel: channel);

      AppLogger.suppressLogging(true);
      final result = await service.getLocationName(
        const Coordinate(latitude: 35.6586, longitude: 139.7454),
      );

      expect(result, isNull);
    });
  });
}
