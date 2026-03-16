import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/coordinate_state.dart';

final coordinateProvider =
    NotifierProvider<CoordinateNotifier, CoordinateState>(
      CoordinateNotifier.new,
    );

class CoordinateNotifier extends Notifier<CoordinateState> {
  GetCurrentLocationUsecase get _getCurrentLocationUsecase =>
      ref.read(getCurrentLocationUsecaseProvider);

  @override
  CoordinateState build() {
    return const CoordinateState();
  }

  Future<void> getCurrentLocation() async {
    try {
      final coordinate = await _getCurrentLocationUsecase.execute();
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
