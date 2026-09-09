import 'package:memora/application/services/nearby_location_service.dart';
import 'package:memora/core/models/coordinate.dart';

class GetNearbyLocationNameUsecase {
  GetNearbyLocationNameUsecase(this._nearbyLocationService);

  final NearbyLocationService _nearbyLocationService;

  Future<String?> execute(Coordinate coordinate) {
    return _nearbyLocationService.getLocationName(coordinate);
  }
}
