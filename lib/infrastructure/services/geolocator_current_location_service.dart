import 'package:geolocator/geolocator.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/core/models/coordinate.dart';

class GeolocatorCurrentLocationService implements CurrentLocationService {
  @override
  Future<Coordinate?> getCurrentLocation() async {
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
    return Coordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
