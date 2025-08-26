import 'package:memora/domain/value-objects/location.dart';

abstract interface class ReverseGeocodingService {
  Future<String?> getLocationName(Location location);
}
