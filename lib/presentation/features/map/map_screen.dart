import 'package:flutter/material.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class MapScreen extends StatelessWidget {
  final bool isTestEnvironment;

  const MapScreen({super.key, this.isTestEnvironment = false});

  void _onMapLongTapped(Location location) {
    // WIP
  }

  void _onMarkerTapped(PinDto pin) {
    // WIP
  }

  void _onMarkerUpdated(PinDto pin) {
    // WIP
  }

  void _onMarkerDeleted(String pinId) {
    // WIP
  }

  @override
  Widget build(BuildContext context) {
    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    return MapViewFactory.create(mapViewType).createMapView(
      pins: const [],
      onMapLongTapped: _onMapLongTapped,
      onMarkerTapped: _onMarkerTapped,
      onMarkerUpdated: _onMarkerUpdated,
      onMarkerDeleted: _onMarkerDeleted,
    );
  }
}
