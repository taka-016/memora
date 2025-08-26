import 'package:memora/domain/value-objects/location.dart';

abstract interface class NearbyLocationService {
  Future<String?> getLocationName(Location location);
}
