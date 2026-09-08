import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';

class SearchLocationsUsecase {
  SearchLocationsUsecase(this._locationSearchService);

  final LocationSearchService _locationSearchService;

  Future<List<LocationCandidateDto>> execute(String keyword) {
    return _locationSearchService.searchByKeyword(keyword);
  }
}
