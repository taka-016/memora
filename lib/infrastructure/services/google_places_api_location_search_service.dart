import 'package:googleapis/places/v1.dart' as places;
import 'package:http/http.dart' as http;
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/infrastructure/services/google_api_key_client.dart';

class GooglePlacesApiLocationSearchService implements LocationSearchService {
  final String apiKey;
  final places.PlacesApi _placesApi;

  GooglePlacesApiLocationSearchService({
    required this.apiKey,
    http.Client? httpClient,
    places.PlacesApi? placesApi,
  }) : _placesApi =
           placesApi ??
           places.PlacesApi(
             GoogleApiKeyClient(apiKey: apiKey, inner: httpClient),
           );

  @override
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword) async {
    final response = await _placesApi.places.searchText(
      places.GoogleMapsPlacesV1SearchTextRequest(
        textQuery: keyword,
        languageCode: 'ja',
      ),
      $fields: 'places.displayName,places.formattedAddress,places.location',
    );

    final results = response.places;
    if (results == null) return const [];
    return results.map<LocationCandidateDto>((place) {
      return LocationCandidateDto(
        name: place.displayName?.text ?? '',
        address: place.formattedAddress ?? '',
        coordinate: Coordinate(
          latitude: place.location?.latitude ?? 0.0,
          longitude: place.location?.longitude ?? 0.0,
        ),
      );
    }).toList();
  }
}
