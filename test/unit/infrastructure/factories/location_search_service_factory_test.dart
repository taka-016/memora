import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/factories/location_search_service_factory.dart';
import 'package:memora/infrastructure/services/places_sdk_location_search_service.dart';

void main() {
  group('LocationSearchServiceFactory', () {
    test('オンラインモードではPlacesSdkLocationSearchServiceを返す', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(locationSearchServiceProvider);

      expect(service, isA<PlacesSdkLocationSearchService>());
    });
  });
}
