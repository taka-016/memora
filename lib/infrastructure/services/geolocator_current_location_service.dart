import 'package:geolocator/geolocator.dart';
import 'package:flutter_verification/domain/services/current_location_service.dart';

class GeolocatorCurrentLocationService implements CurrentLocationService {
  @override
  Future<CurrentLocation?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    return CurrentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
