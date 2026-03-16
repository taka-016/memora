import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';

final locationSearchHttpClientProvider = Provider.autoDispose<http.Client>((
  ref,
) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final locationSearchServiceProvider =
    Provider.autoDispose<LocationSearchService>((ref) {
      return LocationSearchServiceFactory.create<LocationSearchService>(
        httpClient: ref.watch(locationSearchHttpClientProvider),
      );
    });

class LocationSearchServiceFactory {
  static T create<T extends Object>({http.Client? httpClient}) {
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
