import 'package:geolocator/geolocator.dart';
import 'package:flutter_verification/domain/services/location_service.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<CurrentLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return CurrentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
