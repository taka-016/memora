import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:memora/application/usecases/location/get_nearby_location_name_usecase.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/current_location_service_factory.dart';
import 'package:memora/infrastructure/factories/location_search_service_factory.dart';
import 'package:memora/infrastructure/factories/map_view_factory.dart';
import 'package:memora/infrastructure/factories/nearby_location_service_factory.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';

final mapViewBuilderProvider = Provider<MapViewBuilder>((ref) {
  return MapViewFactory.create(ref.watch(appModeProvider));
});

final getCurrentLocationUsecaseProvider = Provider<GetCurrentLocationUsecase>((
  ref,
) {
  return GetCurrentLocationUsecase(ref.watch(currentLocationServiceProvider));
});

final getNearbyLocationNameUsecaseProvider =
    Provider<GetNearbyLocationNameUsecase>((ref) {
      return GetNearbyLocationNameUsecase(
        ref.watch(nearbyLocationServiceProvider),
      );
    });

final searchLocationsUsecaseProvider = Provider<SearchLocationsUsecase>((ref) {
  return SearchLocationsUsecase(ref.watch(locationSearchServiceProvider));
});
