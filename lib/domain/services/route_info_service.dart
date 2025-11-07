import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/core/enums/travel_mode.dart';

abstract class RouteInfoService {
  Future<RouteSegmentDetail> fetchRoute({
    required Location origin,
    required Location destination,
    required TravelMode travelMode,
  });
}
