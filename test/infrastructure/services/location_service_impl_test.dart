import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/infrastructure/services/location_service_impl.dart';

void main() {
  test('LocationServiceImplが生成できる', () {
    final service = LocationServiceImpl();
    expect(service, isA<LocationServiceImpl>());
  });
}
