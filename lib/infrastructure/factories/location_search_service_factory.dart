import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/config/location_search_api_type.dart';
import 'package:memora/infrastructure/config/location_search_api_type_provider.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return LocationSearchServiceFactory.create(ref: ref, httpClient: client);
});

class LocationSearchServiceFactory {
  static LocationSearchService create({
    required Ref ref,
    required http.Client httpClient,
  }) {
    final apiType = ref.watch(locationSearchApiTypeProvider);
    return _createServiceByType(apiType: apiType, httpClient: httpClient);
  }

  static LocationSearchService _createServiceByType({
    required LocationSearchApiType apiType,
    required http.Client httpClient,
  }) {
    switch (apiType) {
      case LocationSearchApiType.googlePlaces:
        return GooglePlacesApiLocationSearchService(
          apiKey: Env.googlePlacesApiKey,
          httpClient: httpClient,
        );
      case LocationSearchApiType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }
}
