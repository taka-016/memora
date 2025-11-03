import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/travel_mode.dart';

abstract class RouteInfoService {
  Future<List<Location>> fetchRoute({
    required Location origin,
    required Location destination,
    required TravelMode travelMode,
  });
}
