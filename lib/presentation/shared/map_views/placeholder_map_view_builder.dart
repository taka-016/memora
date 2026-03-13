import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';

class PlaceholderMapViewBuilder implements MapViewBuilder {
  const PlaceholderMapViewBuilder();

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
    return const PlaceholderMapView();
  }
}
