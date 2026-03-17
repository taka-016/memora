import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/factories/current_location_service_factory.dart';

final getCurrentLocationUsecaseProvider = Provider<GetCurrentLocationUsecase>((
  ref,
) {
  return GetCurrentLocationUsecase(ref.watch(currentLocationServiceProvider));
});

class GetCurrentLocationUsecase {
  GetCurrentLocationUsecase(this._currentLocationService);

  final CurrentLocationService _currentLocationService;

  Future<Coordinate?> execute() {
    return _currentLocationService.getCurrentLocation();
  }
}
