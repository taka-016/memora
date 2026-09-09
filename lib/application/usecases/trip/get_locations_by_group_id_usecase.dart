import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';

class GetLocationsByGroupIdUsecase {
  GetLocationsByGroupIdUsecase(this._locationQueryService);

  final LocationQueryService _locationQueryService;

  Future<List<LocationDto>> execute(String groupId) async {
    return _locationQueryService.getLocationsByGroupId(groupId);
  }
}
