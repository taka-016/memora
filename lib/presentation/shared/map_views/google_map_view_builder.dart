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
    DateTime? tripStartDate,
    bool isReadOnly = false,
    double defaultMarkerHue = 0,
    Set<String> highlightedPinIds = const {},
    double highlightedMarkerHue = 0,
  }) {
    return GoogleMapView(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onSearchedLocationSelected: onSearchedLocationSelected,
      onPinTapped: onPinTapped,
      onPinUpdated: onPinUpdated,
      onPinDeleted: onPinDeleted,
      selectedPin: selectedPin,
      tripStartDate: tripStartDate,
      isReadOnly: isReadOnly,
      defaultMarkerHue: defaultMarkerHue,
      highlightedPinIds: highlightedPinIds,
      highlightedMarkerHue: highlightedMarkerHue,
    );
  }
}
