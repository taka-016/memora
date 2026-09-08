import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';

class GetCurrentLocationUsecase {
  GetCurrentLocationUsecase(this._currentLocationService);

  final CurrentLocationService _currentLocationService;

  Future<Coordinate?> execute() {
    return _currentLocationService.getCurrentLocation();
  }
}
