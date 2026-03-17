import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/services/geolocator_current_location_service.dart';

final currentLocationServiceProvider = Provider<CurrentLocationService>((ref) {
  return CurrentLocationServiceFactory.create<CurrentLocationService>();
});

class CurrentLocationServiceFactory {
  static T create<T extends Object>() {
    if (T == CurrentLocationService) {
      return GeolocatorCurrentLocationService() as T;
    }
    throw ArgumentError('Unknown service type: $T');
  }
}
