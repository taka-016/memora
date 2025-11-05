import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/domain/value_objects/travel_mode.dart';

class GoogleRoutesApiRouteInfoService implements RouteInfoService {
  GoogleRoutesApiRouteInfoService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  @override
  Future<RouteSegmentDetail> fetchRoute({
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
      'languageCode': 'ja-JP',
    };

    if (travelMode == TravelMode.drive) {
      body['routingPreference'] = 'TRAFFIC_AWARE';
    }

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'routes.polyline.encodedPolyline,routes.legs.distanceMeters,'
            'routes.legs.duration,routes.legs.steps.navigationInstruction',
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
      return const RouteSegmentDetail.empty();
    }

    final route = routes.first;
    if (route is! Map<String, dynamic>) {
      return const RouteSegmentDetail.empty();
    }

    String? encodedPolyline;
    final routePolyline = route['polyline'];
    if (routePolyline is Map<String, dynamic>) {
      final candidate = routePolyline['encodedPolyline'];
      if (candidate is String && candidate.isNotEmpty) {
        encodedPolyline = candidate;
      }
    }

    final legs = route['legs'];
    int distanceMeters = 0;
    int durationSeconds = 0;
    final instructions = <String>[];

    if (legs is List && legs.isNotEmpty) {
      final firstLeg = legs.first;
      if (firstLeg is Map<String, dynamic>) {
        final distance = firstLeg['distanceMeters'];
        if (distance is num) {
          distanceMeters = distance.round();
        }
        final durationRaw = firstLeg['duration'];
        if (durationRaw is String) {
          durationSeconds = _parseDurationSeconds(durationRaw);
        }
        final steps = firstLeg['steps'];
        if (steps is List) {
          for (final step in steps) {
            if (step is! Map<String, dynamic>) {
              continue;
            }
            final navigationInstruction = step['navigationInstruction'];
            if (navigationInstruction is! Map<String, dynamic>) {
              continue;
            }
            final instruction = navigationInstruction['instructions'];
            if (instruction is! String || instruction.isEmpty) {
              continue;
            }
            final sanitized = _sanitizeInstruction(instruction);
            if (sanitized.isNotEmpty) {
              instructions.add(sanitized);
            }
          }
        }

        if (encodedPolyline == null) {
          final legPolyline = firstLeg['polyline'];
          if (legPolyline is Map<String, dynamic>) {
            final candidate = legPolyline['encodedPolyline'];
            if (candidate is String && candidate.isNotEmpty) {
              encodedPolyline = candidate;
            }
          }
        }
      }
    }

    if (encodedPolyline == null || encodedPolyline.isEmpty) {
      return RouteSegmentDetail(
        polyline: const <Location>[],
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        instructions: instructions,
      );
    }

    final coordinates = _decodePolyline(encodedPolyline);
    return RouteSegmentDetail(
      polyline: coordinates,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      instructions: instructions,
    );
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

  int _parseDurationSeconds(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return 0;
    }
    final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)s$').firstMatch(normalized);
    if (match == null) {
      return 0;
    }
    final value = double.tryParse(match.group(1)!);
    if (value == null) {
      return 0;
    }
    return value.round();
  }

  String _sanitizeInstruction(String instruction) {
    return instruction.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
