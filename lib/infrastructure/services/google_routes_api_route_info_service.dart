import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/travel_mode.dart';

class GoogleRoutesApiRouteInfoService implements RouteInfoService {
  GoogleRoutesApiRouteInfoService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  @override
  Future<List<Location>> fetchRoute({
    required Location origin,
    required Location destination,
    required TravelMode travelMode,
  }) async {
    final url = Uri.https(
      'routes.googleapis.com',
      'directions/v2:computeRoutes',
    );

    final body = {
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      'travelMode': travelMode.apiValue,
      'computeAlternativeRoutes': false,
    };

    if (travelMode == TravelMode.drive) {
      body['routingPreference'] = 'TRAFFIC_AWARE';
    }

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch routes: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      return const [];
    }

    final polyline = routes.first['polyline']?['encodedPolyline'];
    if (polyline is! String || polyline.isEmpty) {
      return const [];
    }

    return _decodePolyline(polyline);
  }

  List<Location> _decodePolyline(String encoded) {
    final List<Location> coordinates = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) {
          break;
        }
      }
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) {
          break;
        }
      }
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      coordinates.add(Location(latitude: lat / 1e5, longitude: lng / 1e5));
    }

    return coordinates;
  }
}
