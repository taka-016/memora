import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memora/infrastructure/config/location_search_api_type.dart';
import 'package:memora/infrastructure/config/location_search_api_type_provider.dart';
import 'package:memora/infrastructure/factories/location_search_service_factory.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';

void main() {
  group('LocationSearchServiceFactory', () {
    test('googlePlaces指定時はGooglePlacesApiLocationSearchServiceを返す', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(locationSearchServiceProvider);

      expect(service, isA<GooglePlacesApiLocationSearchService>());
    });

    test('local指定時は未実装エラーを投げる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(locationSearchApiTypeProvider.notifier).state =
          LocationSearchApiType.local;

      expect(
        () => container.read(locationSearchServiceProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('未知のサービス型指定時はArgumentErrorを投げる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final client = http.Client();
      addTearDown(client.close);
      final unknownServiceProvider = Provider<String>((ref) {
        return LocationSearchServiceFactory.create<String>(
          ref: ref,
          httpClient: client,
        );
      });

      expect(
        () => container.read(unknownServiceProvider),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
