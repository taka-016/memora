import 'dart:convert';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:memora/domain/value-objects/location.dart' as domain;
import 'package:http/http.dart' as http;

class GooglePlacesApiNearbyLocationService implements NearbyLocationService {
  final String apiKey;
  final http.Client httpClient;

  GooglePlacesApiNearbyLocationService({
    required this.apiKey,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  @override
  Future<String?> getLocationName(domain.Location location) async {
    try {
      return await _getPlaceNameFromNearbySearch(location);
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getPlaceNameFromNearbySearch(
    domain.Location location,
  ) async {
    try {
      if (apiKey.isEmpty) {
        return null;
      }

      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchNearby',
      );

      final response = await httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask':
              'places.displayName,places.primaryType,places.types',
        },
        body: jsonEncode({
          'maxResultCount': 1,
          'rankPreference': 'DISTANCE',
          'languageCode': 'ja',
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'radius': 100.0,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List?;

        if (places != null && places.isNotEmpty) {
          final place = places.first;
          final displayName = place['displayName']?['text'];

          if (displayName != null &&
              displayName is String &&
              displayName.isNotEmpty) {
            return displayName;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
