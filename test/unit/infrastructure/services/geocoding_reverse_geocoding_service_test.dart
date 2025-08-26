import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value-objects/location.dart' as domain;
import 'package:memora/infrastructure/services/geocoding_reverse_geocoding_service.dart';

void main() {
  group('GeocodingReverseGeocodingService', () {
    late GeocodingReverseGeocodingService service;

    setUp(() {
      service = const GeocodingReverseGeocodingService();
    });

    group('getLocationName', () {
      test('serviceが正しく初期化される', () {
        expect(service, isNotNull);
        expect(service, isA<GeocodingReverseGeocodingService>());
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
