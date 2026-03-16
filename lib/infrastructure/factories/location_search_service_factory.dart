import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  return LocationSearchServiceFactory.create<LocationSearchService>();
});

class LocationSearchServiceFactory {
  static T create<T extends Object>() {
    if (T == LocationSearchService) {
      return GooglePlacesApiLocationSearchService(
            apiKey: Env.googlePlacesApiKey,
          )
          as T;
    }
    throw ArgumentError('Unknown service type: $T');
  }
}
