import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/infrastructure/services/geolocator_location_service.dart';

void main() {
  test('GeolocatorLocationServiceが生成できる', () {
    final service = GeolocatorLocationService();
    expect(service, isA<GeolocatorLocationService>());
  });
}
