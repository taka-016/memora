import 'package:memora/domain/entities/trip/route.dart';

abstract class RouteRepository {
  Future<void> saveRoute(Route route);
  Future<void> updateRoute(Route route);
  Future<void> deleteRoute(String routeId);
  Future<void> deleteRoutesByPinId(String pinId);
}
