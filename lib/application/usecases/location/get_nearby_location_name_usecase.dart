import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/nearby_location_service.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/infrastructure/factories/nearby_location_service_factory.dart';

final getNearbyLocationNameUsecaseProvider =
    Provider<GetNearbyLocationNameUsecase>((ref) {
      return GetNearbyLocationNameUsecase(
        ref.watch(nearbyLocationServiceProvider),
      );
    });

class GetNearbyLocationNameUsecase {
  GetNearbyLocationNameUsecase(this._nearbyLocationService);

  final NearbyLocationService _nearbyLocationService;

  Future<String?> execute(Coordinate coordinate) {
    return _nearbyLocationService.getLocationName(coordinate);
  }
}
