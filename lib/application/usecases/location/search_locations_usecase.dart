import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/infrastructure/factories/location_search_service_factory.dart';

final searchLocationsUsecaseProvider =
    Provider.autoDispose<SearchLocationsUsecase>((ref) {
      return SearchLocationsUsecase(ref.watch(locationSearchServiceProvider));
    });

class SearchLocationsUsecase {
  SearchLocationsUsecase(this._locationSearchService);

  final LocationSearchService _locationSearchService;

  Future<List<LocationCandidateDto>> execute(String keyword) {
    return _locationSearchService.searchByKeyword(keyword);
  }
}
