import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return _createLocationSearchService(httpClient: client);
});

LocationSearchService _createLocationSearchService({
  required http.Client httpClient,
}) {
  return GooglePlacesApiLocationSearchService(
    apiKey: Env.googlePlacesApiKey,
    httpClient: httpClient,
  );
}
