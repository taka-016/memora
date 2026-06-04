import 'package:memora/application/dtos/trip/location_dto.dart';

abstract class LocationQueryService {
  Future<List<LocationDto>> getLocationsByGroupId(String groupId);
}
