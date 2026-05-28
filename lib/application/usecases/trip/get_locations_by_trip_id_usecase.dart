import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getLocationsByTripIdUsecaseProvider =
    Provider<GetLocationsByTripIdUsecase>((ref) {
      return GetLocationsByTripIdUsecase(
        ref.watch(locationQueryServiceProvider),
      );
    });

class GetLocationsByTripIdUsecase {
  GetLocationsByTripIdUsecase(this._locationQueryService);

  final LocationQueryService _locationQueryService;

  Future<List<LocationDto>> execute(String tripId) async {
    return _locationQueryService.getLocationsByTripId(tripId);
  }
}
