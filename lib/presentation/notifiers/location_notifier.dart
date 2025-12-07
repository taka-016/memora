import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/location_state.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/services/geolocator_current_location_service.dart';
import 'package:memora/core/app_logger.dart';

final currentLocationServiceProvider = Provider<CurrentLocationService>((ref) {
  return GeolocatorCurrentLocationService();
});

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);

class LocationNotifier extends Notifier<LocationState> {
  CurrentLocationService get _currentLocationService =>
      ref.read(currentLocationServiceProvider);

  @override
  LocationState build() {
    return const LocationState();
  }

  Future<void> getCurrentLocation() async {
    try {
      final location = await _currentLocationService.getCurrentLocation();
      if (location != null) {
        state = state.copyWith(location: location, lastUpdated: DateTime.now());
      }
    } catch (e, stack) {
      logger.e(
        'LocationNotifier.getCurrentLocation: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void setLocation(Location location) {
    state = state.copyWith(location: location, lastUpdated: DateTime.now());
  }

  void clearLocation() {
    state = const LocationState();
  }
}
