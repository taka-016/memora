import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getLocationsByGroupIdUsecaseProvider =
    Provider<GetLocationsByGroupIdUsecase>((ref) {
      return GetLocationsByGroupIdUsecase(
        ref.watch(locationQueryServiceProvider),
      );
    });

class GetLocationsByGroupIdUsecase {
  GetLocationsByGroupIdUsecase(this._locationQueryService);

  final LocationQueryService _locationQueryService;

  Future<List<LocationDto>> execute(String groupId) async {
    return _locationQueryService.getLocationsByGroupId(groupId);
  }
}
