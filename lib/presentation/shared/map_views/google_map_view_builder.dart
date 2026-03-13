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
    Function(Coordinate)? onMapLongTapped,
    Function(LocationCandidateDto)? onSearchCandidateSelected,
    Function(PinDto)? onMarkerTapped,
    Function(PinDto)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  }) {
    return GoogleMapView(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onSearchCandidateSelected: onSearchCandidateSelected,
      onMarkerTapped: onMarkerTapped,
      onMarkerUpdated: onMarkerUpdated,
      onMarkerDeleted: onMarkerDeleted,
      selectedPin: selectedPin,
      isReadOnly: isReadOnly,
    );
  }
}
