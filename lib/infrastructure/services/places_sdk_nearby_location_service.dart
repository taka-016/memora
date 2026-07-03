import 'package:flutter/services.dart';
import 'package:memora/application/services/nearby_location_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';

class PlacesSdkNearbyLocationService implements NearbyLocationService {
  PlacesSdkNearbyLocationService({
    this._channel = const MethodChannel('memora/places'),
  });

  static const double _radiusMeters = 50.0;
  static const int _maxResultCount = 1;

  final MethodChannel _channel;

  @override
  Future<String?> getLocationName(Coordinate coordinate) async {
    try {
      return await _channel.invokeMethod<String>('searchNearby', {
        'latitude': coordinate.latitude,
        'longitude': coordinate.longitude,
        'radiusMeters': _radiusMeters,
        'maxResultCount': _maxResultCount,
      });
    } catch (e, stack) {
      logger.e(
        'PlacesSdkNearbyLocationService.getLocationName: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
