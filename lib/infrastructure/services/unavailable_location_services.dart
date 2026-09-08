import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/services/nearby_location_service.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';

class UnavailableLocationSearchService implements LocationSearchService {
  const UnavailableLocationSearchService();
  @override
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword) async {
    throw const FeatureUnavailableException(
      AppFeature.locationSearch,
      'この機能はオンラインモードで利用できます。',
    );
  }
}

class UnavailableCurrentLocationService implements CurrentLocationService {
  const UnavailableCurrentLocationService();
  @override
  Future<Coordinate?> getCurrentLocation() async {
    throw const FeatureUnavailableException(
      AppFeature.currentLocation,
      'この機能はオンラインモードで利用できます。',
    );
  }
}

class UnavailableNearbyLocationService implements NearbyLocationService {
  const UnavailableNearbyLocationService();
  @override
  Future<String?> getLocationName(Coordinate coordinate) async {
    throw const FeatureUnavailableException(
      AppFeature.locationSearch,
      'この機能はオンラインモードで利用できます。',
    );
  }
}
