import 'package:flutter/material.dart';
import 'package:memora/domain/services/map_view_service.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/widgets/google_map_view.dart';

/// Google Maps を使用した地図ビューサービスの実装
class GoogleMapViewService implements MapViewService {
  final CurrentLocationService? _locationService;

  const GoogleMapViewService({CurrentLocationService? locationService})
    : _locationService = locationService;

  @override
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(String)? onMarkerDeleted,
  }) {
    return GoogleMapView(
      pins: pins,
      locationService: _locationService,
      onMapLongTapped: onMapLongTapped,
      onMarkerTapped: onMarkerTapped,
      onMarkerDeleted: onMarkerDeleted,
    );
  }
}
