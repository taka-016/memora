import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_leg.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';

class GoogleRoutesApiRouteInformationService
    implements RouteInformationService {
  final String apiKey;
  final http.Client httpClient;

  GoogleRoutesApiRouteInformationService({
    required this.apiKey,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  @override
  Future<List<RouteCandidate>> fetchRoutes({
    required List<RouteLocation> locations,
    required RouteTravelMode travelMode,
  }) async {
    if (locations.length < 2) {
      return const [];
    }

    final uri = Uri.https(
      'routes.googleapis.com',
      '/directions/v2:computeRoutes',
    );

    final body = <String, dynamic>{
      'origin': _toWaypoint(locations.first),
      'destination': _toWaypoint(locations.last),
      'computeAlternativeRoutes': true,
      'languageCode': 'ja',
      'units': 'METRIC',
      'routingPreference': 'TRAFFIC_UNAWARE',
    };

    if (locations.length > 2) {
      body['intermediates'] = locations
          .sublist(1, locations.length - 1)
          .map(_toWaypoint)
          .toList();
    }

    final travelModeValue = travelMode.apiValue;
    if (travelModeValue != null) {
      body['travelMode'] = travelModeValue;
    }

    final response = await httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch routes: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final routes = decoded['routes'];
    if (routes is! List) {
      return const [];
    }

    return routes
        .map<RouteCandidate>((route) => _parseRouteCandidate(route))
        .toList();
  }

  Map<String, dynamic> _toWaypoint(RouteLocation location) {
    return {
      'location': {
        'latLng': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      },
    };
  }

  RouteCandidate _parseRouteCandidate(dynamic route) {
    if (route is! Map<String, dynamic>) {
      return const RouteCandidate(legs: [], warnings: []);
    }

    final routeMap = route;

    final legs = routeMap['legs'];
    final parsedLegs = <RouteLeg>[];
    if (legs is List) {
      for (final leg in legs) {
        parsedLegs.add(_parseLeg(leg));
      }
    }

    final warnings = <String>[];
    final rawWarnings = routeMap['warnings'];
    if (rawWarnings is List) {
      for (final warning in rawWarnings) {
        if (warning is String) {
          warnings.add(warning);
        }
      }
    }

    return RouteCandidate(
      description: routeMap['description'] as String?,
      localizedDistanceText: _extractLocalizedText(routeMap, 'distance'),
      localizedDurationText: _extractLocalizedText(routeMap, 'duration'),
      legs: parsedLegs,
      warnings: warnings,
    );
  }

  RouteLeg _parseLeg(dynamic leg) {
    if (leg is! Map<String, dynamic>) {
      return const RouteLeg();
    }

    final legMap = leg;

    final steps = legMap['steps'];
    String? instruction;
    if (steps is List) {
      for (final step in steps) {
        if (step is Map<String, dynamic>) {
          final navInstruction = step['navigationInstruction'];
          if (navInstruction is Map<String, dynamic>) {
            final text = navInstruction['instructions'];
            if (text is String && text.isNotEmpty) {
              instruction = text;
              break;
            }
          }
        }
      }
    }

    instruction ??= '経路概要情報が取得できませんでした';

    return RouteLeg(
      localizedDistanceText: _extractLocalizedText(legMap, 'distance'),
      localizedDurationText: _extractLocalizedText(legMap, 'duration'),
      primaryInstruction: instruction,
    );
  }

  String? _extractLocalizedText(Map<String, dynamic> source, String key) {
    final localizedValues = source['localizedValues'];
    if (localizedValues is Map<String, dynamic>) {
      final target = localizedValues[key];
      if (target is Map<String, dynamic>) {
        final text = target['text'];
        if (text is String) {
          return text;
        }
      }
    }
    return null;
  }
}

const String _fieldMask =
    'routes.distanceMeters,'
    'routes.duration,'
    'routes.description,'
    'routes.localizedValues.duration,'
    'routes.localizedValues.distance,'
    'routes.warnings,'
    'routes.legs.distanceMeters,'
    'routes.legs.duration,'
    'routes.legs.localizedValues.duration,'
    'routes.legs.localizedValues.distance,'
    'routes.legs.steps.navigationInstruction.instructions';
