import 'package:memora/application/dtos/trip/route_segment_detail_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/core/models/coordinate.dart';

abstract class RouteInfoService {
  Future<RouteSegmentDetailDto> fetchRoute({
    required Coordinate origin,
    required Coordinate destination,
    required TravelMode travelMode,
  });
}
