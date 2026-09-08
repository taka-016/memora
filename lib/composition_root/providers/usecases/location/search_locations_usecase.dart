import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/infrastructure/factories/location_search_service_factory.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';

final searchLocationsUsecaseProvider = Provider<SearchLocationsUsecase>((ref) {
  return SearchLocationsUsecase(ref.watch(locationSearchServiceProvider));
});
