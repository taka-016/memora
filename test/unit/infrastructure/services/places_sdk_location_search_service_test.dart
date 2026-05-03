import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/places_sdk_location_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('memora/places');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PlacesSdkLocationSearchService', () {
    test('検索キーワードをText Searchへ渡して候補へ変換する', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            capturedCall = call;
            return [
              {
                'name': '東京タワー',
                'address': '東京都港区芝公園4丁目2-8',
                'latitude': 35.6586,
                'longitude': 139.7454,
              },
            ];
          });

      final service = PlacesSdkLocationSearchService(channel: channel);

      final results = await service.searchByKeyword('東京タワー');

      expect(capturedCall?.method, 'searchByText');
      expect(capturedCall?.arguments, {'query': '東京タワー'});
      expect(results, hasLength(1));
      expect(results.first.name, '東京タワー');
      expect(results.first.address, '東京都港区芝公園4丁目2-8');
      expect(results.first.coordinate.latitude, 35.6586);
      expect(results.first.coordinate.longitude, 139.7454);
    });
  });
}
