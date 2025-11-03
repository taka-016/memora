import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';

abstract class RouteInformationService {
  Future<List<RouteCandidate>> fetchRoutes({
    required List<RouteLocation> locations,
    required RouteTravelMode travelMode,
    DateTime? departureTime,
  });
}
