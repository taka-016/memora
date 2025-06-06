abstract class CurrentLocationService {
  Future<CurrentLocation?> getCurrentLocation();
}

class CurrentLocation {
  final double latitude;
  final double longitude;
  const CurrentLocation({required this.latitude, required this.longitude});
}
