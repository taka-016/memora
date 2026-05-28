import 'package:memora/domain/entities/trip/location.dart';

abstract class LocationRepository {
  Future<void> saveLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String locationId);
}
