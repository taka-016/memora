import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:memora/application/services/route_info_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/config/route_info_api_type.dart';
import 'package:memora/infrastructure/config/route_info_api_type_provider.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';

final routeInfoHttpClientFactoryProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final routeInfoHttpClientProvider = Provider<http.Client>((ref) {
  final client = ref.watch(routeInfoHttpClientFactoryProvider);
  ref.onDispose(client.close);
  return client;
});

final routeInfoServiceProvider = Provider<RouteInfoService>((ref) {
  return RouteInfoServiceFactory.create(ref: ref);
});

class RouteInfoServiceFactory {
  static RouteInfoService create({required Ref ref}) {
    final apiType = ref.watch(routeInfoApiTypeProvider);
    return _createServiceByType(ref: ref, apiType: apiType);
  }

  static RouteInfoService _createServiceByType({
    required Ref ref,
    required RouteInfoApiType apiType,
  }) {
    switch (apiType) {
      case RouteInfoApiType.googleRoutes:
        return GoogleRoutesApiRouteInfoService(
          apiKey: Env.googlePlacesApiKey,
          httpClient: ref.watch(routeInfoHttpClientProvider),
        );
      case RouteInfoApiType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }
}
