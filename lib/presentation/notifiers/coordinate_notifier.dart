import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/notifiers/coordinate_state.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/services/geolocator_current_location_service.dart';
import 'package:memora/core/app_logger.dart';

final currentLocationServiceProvider = Provider<CurrentLocationService>((ref) {
  return GeolocatorCurrentLocationService();
});

final coordinateProvider =
    NotifierProvider<CoordinateNotifier, CoordinateState>(
      CoordinateNotifier.new,
    );

class CoordinateNotifier extends Notifier<CoordinateState> {
  CurrentLocationService get _currentLocationService =>
      ref.read(currentLocationServiceProvider);

  @override
  CoordinateState build() {
    return const CoordinateState();
  }

  Future<void> getCurrentLocation() async {
    try {
      final coordinate = await _currentLocationService.getCurrentLocation();
      if (coordinate != null) {
        state = state.copyWith(
          coordinate: coordinate,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e, stack) {
      logger.e(
        'CoordinateNotifier.getCurrentLocation: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void setCoordinate(Coordinate coordinate) {
    state = state.copyWith(coordinate: coordinate, lastUpdated: DateTime.now());
  }

  void clearCoordinate() {
    state = const CoordinateState();
  }
}
