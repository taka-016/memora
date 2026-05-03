import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/infrastructure/config/location_search_api_type.dart';
import 'package:memora/infrastructure/config/location_search_api_type_provider.dart';
import 'package:memora/infrastructure/services/places_sdk_location_search_service.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  return LocationSearchServiceFactory.create(ref: ref);
});

class LocationSearchServiceFactory {
  static LocationSearchService create({required Ref ref}) {
    final apiType = ref.watch(locationSearchApiTypeProvider);
    return _createServiceByType(apiType: apiType);
  }

  static LocationSearchService _createServiceByType({
    required LocationSearchApiType apiType,
  }) {
    switch (apiType) {
      case LocationSearchApiType.googlePlaces:
        return PlacesSdkLocationSearchService();
      case LocationSearchApiType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }
}
