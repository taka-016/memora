import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/config/route_info_api_type.dart';

final routeInfoApiTypeProvider = StateProvider<RouteInfoApiType>(
  (ref) => RouteInfoApiType.googleRoutes,
);
