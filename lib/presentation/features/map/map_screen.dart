import 'package:flutter/material.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class MapScreen extends StatelessWidget {
  final List<PinDto> pins;
  final Function(Location)? onMapLongTapped;
  final Function(PinDto)? onMarkerTapped;
  final Function(PinDto)? onMarkerUpdated;
  final Function(String)? onMarkerDeleted;
  final PinDto? selectedPin;
  final bool isTestEnvironment;

  const MapScreen({
    super.key,
    required this.pins,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerUpdated,
    this.onMarkerDeleted,
    this.selectedPin,
    this.isTestEnvironment = false,
  });

  @override
  Widget build(BuildContext context) {
    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    return MapViewFactory.create(mapViewType).createMapView(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onMarkerTapped: onMarkerTapped,
      onMarkerUpdated: onMarkerUpdated,
      onMarkerDeleted: onMarkerDeleted,
      selectedPin: selectedPin,
    );
  }
}
