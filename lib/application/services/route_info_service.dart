import 'package:memora/application/dtos/trip/route_segment_detail_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/value_objects/location.dart';

abstract class RouteInfoService {
  Future<RouteSegmentDetailDto> fetchRoute({
    required Location origin,
    required Location destination,
    required TravelMode travelMode,
  });
}
