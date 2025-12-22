import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';

final routeInfoServiceProvider = Provider<RouteInfoService>((ref) {
  return GoogleRoutesApiRouteInfoService(apiKey: Env.googlePlacesApiKey);
});
