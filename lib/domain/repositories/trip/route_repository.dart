import 'package:memora/domain/entities/trip/route.dart';

abstract class RouteRepository {
  Future<void> saveRoutes(String tripId, List<Route> routes);
  Future<void> updateRoutes(String tripId, List<Route> routes);
  Future<void> deleteRoutes(String tripId);
  Future<void> deleteRoutesByPinId(String pinId);
}
