import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/models/coordinate.dart';

abstract class MapViewBuilder {
  Widget createMapView({
    required List<PinDto> pins,
    Function(Coordinate)? onMapLongTapped,
    Function(LocationCandidateDto)? onSearchCandidateSelected,
    Function(PinDto)? onMarkerTapped,
    Function(PinDto)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  });
}
