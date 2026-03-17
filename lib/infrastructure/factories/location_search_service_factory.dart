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
  return LocationSearchServiceFactory.create<LocationSearchService>(
    ref: ref,
    httpClient: client,
  );
});

class LocationSearchServiceFactory {
  static T create<T extends Object>({
    required Ref ref,
    required http.Client httpClient,
  }) {
    final apiType = ref.watch(locationSearchApiTypeProvider);
    return _createServiceByType<T>(apiType: apiType, httpClient: httpClient);
  }

  static T _createServiceByType<T extends Object>({
    required LocationSearchApiType apiType,
    required http.Client httpClient,
  }) {
    switch (apiType) {
      case LocationSearchApiType.googlePlaces:
        return _createGooglePlacesService<T>(httpClient: httpClient);
      case LocationSearchApiType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }

  static T _createGooglePlacesService<T extends Object>({
    required http.Client httpClient,
  }) {
    if (T == LocationSearchService) {
      return GooglePlacesApiLocationSearchService(
            apiKey: Env.googlePlacesApiKey,
            httpClient: httpClient,
          )
          as T;
    }
    throw ArgumentError('Unknown service type: $T');
  }
}
