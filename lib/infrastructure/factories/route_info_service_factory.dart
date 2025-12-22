import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/config/route_info_api_type.dart';
import 'package:memora/infrastructure/config/route_info_api_type_provider.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';

final routeInfoServiceProvider = Provider<RouteInfoService>((ref) {
  return RouteInfoServiceFactory.create<RouteInfoService>(ref: ref);
});

class RouteInfoServiceFactory {
  static T create<T extends Object>({required Ref ref}) {
    final apiType = ref.watch(routeInfoApiTypeProvider);
    return _createServiceByType<T>(apiType);
  }

  static T _createServiceByType<T extends Object>(RouteInfoApiType apiType) {
    switch (apiType) {
      case RouteInfoApiType.googleRoutes:
        return _createGoogleRoutesService<T>();
      case RouteInfoApiType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }

  static T _createGoogleRoutesService<T>() {
    if (T == RouteInfoService) {
      return GoogleRoutesApiRouteInfoService(apiKey: Env.googlePlacesApiKey)
          as T;
    }
    throw ArgumentError('Unknown service type: $T');
  }
}
