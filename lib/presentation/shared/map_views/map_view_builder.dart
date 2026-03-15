import 'package:flutter/material.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/models/coordinate.dart';

abstract class MapViewBuilder {
  Widget createMapView({
    required List<PinDto> pins,
    ValueChanged<Coordinate>? onMapLongTapped,
    ValueChanged<LocationCandidateDto>? onSearchedLocationSelected,
    ValueChanged<PinDto>? onPinTapped,
    ValueChanged<PinDto>? onPinUpdated,
    ValueChanged<String>? onPinDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  });
}
