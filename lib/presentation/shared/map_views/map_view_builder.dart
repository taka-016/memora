import 'package:flutter/material.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/domain/value_objects/location.dart';

abstract class MapViewBuilder {
  Widget createMapView({
    required List<PinDto> pins,
    Function(Location)? onMapLongTapped,
    Function(PinDto)? onMarkerTapped,
    Function(PinDto)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  });
}
