import 'package:googleapis/places/v1.dart' as places;
import 'package:http/http.dart' as http;
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:memora/infrastructure/services/google_api_key_client.dart';

class GooglePlacesApiNearbyLocationService implements NearbyLocationService {
  final String apiKey;
  final places.PlacesApi _placesApi;

  GooglePlacesApiNearbyLocationService({
    required this.apiKey,
    http.Client? httpClient,
    places.PlacesApi? placesApi,
  }) : _placesApi =
           placesApi ??
           places.PlacesApi(
             GoogleApiKeyClient(apiKey: apiKey, inner: httpClient),
           );

  @override
  Future<String?> getLocationName(Coordinate coordinate) async {
    try {
      return await _getPlaceNameFromNearbySearch(coordinate);
    } catch (e, stack) {
      logger.e(
        'GooglePlacesApiNearbyLocationService.getLocationName: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<String?> _getPlaceNameFromNearbySearch(Coordinate coordinate) async {
    try {
      if (apiKey.isEmpty) {
        return null;
      }

      final response = await _placesApi.places.searchNearby(
        places.GoogleMapsPlacesV1SearchNearbyRequest(
          maxResultCount: 1,
          rankPreference: 'POPULARITY',
          languageCode: 'ja',
          locationRestriction:
              places.GoogleMapsPlacesV1SearchNearbyRequestLocationRestriction(
                circle: places.GoogleMapsPlacesV1Circle(
                  center: places.GoogleTypeLatLng(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                  ),
                  radius: 50.0,
                ),
              ),
        ),
        $fields: 'places.displayName',
      );

      final responsePlaces = response.places;

      if (responsePlaces != null && responsePlaces.isNotEmpty) {
        final displayName = responsePlaces.first.displayName?.text;

        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }

      return null;
    } catch (e, stack) {
      logger.e(
        'GooglePlacesApiNearbyLocationService._getPlaceNameFromNearbySearch: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
