import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/models/coordinate.dart';

typedef LocationDetailBuilder =
    Widget Function(
      LocationDto location,
      VoidCallback onClose, {
      VoidCallback? onPreviousLocation,
      VoidCallback? onNextLocation,
    });

abstract class MapViewBuilder {
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
  });
}
