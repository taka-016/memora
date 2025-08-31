import 'package:memora/domain/value_objects/location.dart';

abstract interface class NearbyLocationService {
  Future<String?> getLocationName(Location location);
}
