import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';

class GoogleMapViewBuilder implements MapViewBuilder {
  const GoogleMapViewBuilder();

  @override
  Widget createMapView({
    required List<PinDto> pins,
    ValueChanged<Coordinate>? onMapLongTapped,
    ValueChanged<LocationCandidateDto>? onSearchedLocationSelected,
    ValueChanged<PinDto>? onPinTapped,
    ValueChanged<PinDto>? onPinUpdated,
    ValueChanged<String>? onPinDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  }) {
    return GoogleMapView(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onSearchedLocationSelected: onSearchedLocationSelected,
      onPinTapped: onPinTapped,
      onPinUpdated: onPinUpdated,
      onPinDeleted: onPinDeleted,
      selectedPin: selectedPin,
      isReadOnly: isReadOnly,
    );
  }
}
