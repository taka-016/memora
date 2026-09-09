import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/current_location_service.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/geolocator_current_location_service.dart';
import 'package:memora/infrastructure/services/unavailable_location_services.dart';

final currentLocationServiceProvider = Provider<CurrentLocationService>((ref) {
  return CurrentLocationServiceFactory.create(ref.watch(appModeProvider));
});

class CurrentLocationServiceFactory {
  static CurrentLocationService create(AppMode mode) => switch (mode) {
    AppMode.online => GeolocatorCurrentLocationService(),
    AppMode.offline => const UnavailableCurrentLocationService(),
  };
}
