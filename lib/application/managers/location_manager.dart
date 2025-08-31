import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/location_state.dart';
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
      final location = await _currentLocationService.getCurrentLocation();
      if (location != null) {
        state = state.copyWith(location: location, lastUpdated: DateTime.now());
      }
    } catch (e) {
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
