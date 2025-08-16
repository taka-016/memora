import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/location_state.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/services/geolocator_current_location_service.dart';

final locationProvider = StateNotifierProvider<LocationManager, LocationState>((
  ref,
) {
  return LocationManager(GeolocatorCurrentLocationService());
});

class LocationManager extends StateNotifier<LocationState> {
  final CurrentLocationService _currentLocationService;

  LocationManager(this._currentLocationService) : super(const LocationState());

  Future<void> getCurrentLocation() async {
    try {
      final currentLocation = await _currentLocationService
          .getCurrentLocation();
      if (currentLocation != null) {
        state = state.copyWith(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      lastUpdated: DateTime.now(),
    );
  }

  void clearLocation() {
    state = const LocationState();
  }
}
