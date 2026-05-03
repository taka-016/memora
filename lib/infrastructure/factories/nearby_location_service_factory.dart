import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/nearby_location_service.dart';
import 'package:memora/infrastructure/services/places_sdk_nearby_location_service.dart';

final nearbyLocationServiceProvider = Provider<NearbyLocationService>((ref) {
  return PlacesSdkNearbyLocationService();
});
