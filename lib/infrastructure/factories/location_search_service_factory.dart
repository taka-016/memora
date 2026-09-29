import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/places_sdk_location_search_service.dart';
import 'package:memora/infrastructure/services/unavailable_location_services.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  return LocationSearchServiceFactory.create(ref.watch(appModeProvider));
});

class LocationSearchServiceFactory {
  static LocationSearchService create(AppMode mode) => switch (mode) {
    AppMode.online => PlacesSdkLocationSearchService(),
    AppMode.offline => const UnavailableLocationSearchService(),
  };
}
