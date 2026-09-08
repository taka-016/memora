import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/core/models/coordinate.dart';

class UnavailableMapViewBuilder implements MapViewBuilder {
  const UnavailableMapViewBuilder(this.reason);

  final String reason;

  @override
  Widget createMapView({
    required List<LocationDto> locations,
    ValueChanged<Coordinate>? onMapLongTapped,
    ValueChanged<LocationCandidateDto>? onSearchedLocationSelected,
    ValueChanged<LocationDto>? onLocationTapped,
    LocationDto? selectedLocation,
    LocationDto? focusedLocation,
    Widget? topLeadingOverlay,
    bool highlightSelectedLocation = false,
    LocationDetailBuilder? locationDetailBuilder,
    double? locationDetailBottomSheetHeight,
    DateTime? tripStartDate,
    bool isReadOnly = false,
  }) {
    return Center(child: Text(reason));
  }
}
