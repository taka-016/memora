import 'package:memora/core/models/coordinate.dart';

abstract interface class NearbyLocationService {
  Future<String?> getLocationName(Coordinate location);
}
