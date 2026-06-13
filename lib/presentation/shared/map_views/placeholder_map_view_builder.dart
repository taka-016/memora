import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';

class PlaceholderMapViewBuilder implements MapViewBuilder {
  const PlaceholderMapViewBuilder();

  @override
  Widget createMapView({
    required List<LocationDto> locations,
    ValueChanged<Coordinate>? onMapLongTapped,
    ValueChanged<LocationCandidateDto>? onSearchedLocationSelected,
    ValueChanged<LocationDto>? onLocationTapped,
    LocationDto? selectedLocation,
    bool highlightSelectedLocation = false,
    LocationDetailBuilder? locationDetailBuilder,
    double? locationDetailBottomSheetHeight,
    DateTime? tripStartDate,
    bool isReadOnly = false,
  }) {
    return const PlaceholderMapView();
  }
}
