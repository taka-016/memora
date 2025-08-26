import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value-objects/location.dart' as domain;
import 'package:memora/infrastructure/services/google_places_api_nearby_location_service.dart';

void main() {
  group('GooglePlacesApiNearbyLocationService', () {
    late GooglePlacesApiNearbyLocationService service;

    setUp(() {
      service = GooglePlacesApiNearbyLocationService(apiKey: 'test-api-key');
    });

    group('getLocationName', () {
      test('serviceが正しく初期化される', () {
        expect(service, isNotNull);
        expect(service, isA<GooglePlacesApiNearbyLocationService>());
      });

      test('有効なLocationオブジェクトを受け取れる', () {
        const location = domain.Location(
          latitude: 35.6762,
          longitude: 139.6503,
        );

        expect(location.latitude, equals(35.6762));
        expect(location.longitude, equals(139.6503));
      });

      test('メソッドが定義されている', () {
        const location = domain.Location(latitude: 35.0, longitude: 139.0);

        final result = service.getLocationName(location);
        expect(result, isA<Future<String?>>());
      });
    });
  });
}
