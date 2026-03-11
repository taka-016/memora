import 'package:memora/application/dtos/location/location_candidate_dto.dart';

abstract class LocationSearchService {
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword);
}
