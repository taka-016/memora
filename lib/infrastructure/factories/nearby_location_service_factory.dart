import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/nearby_location_service.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/places_sdk_nearby_location_service.dart';
import 'package:memora/infrastructure/services/unavailable_location_services.dart';

final nearbyLocationServiceProvider = Provider<NearbyLocationService>((ref) {
  return NearbyLocationServiceFactory.create(ref.watch(appModeProvider));
});

class NearbyLocationServiceFactory {
  static NearbyLocationService create(AppMode mode) => switch (mode) {
    AppMode.online => PlacesSdkNearbyLocationService(),
    AppMode.offline => const UnavailableNearbyLocationService(),
  };
}
