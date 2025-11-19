import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class RouteQueryService {
  Future<List<RouteDto>> getRoutesByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  });
}
