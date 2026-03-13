import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/models/coordinate.dart';

abstract class MapViewBuilder {
  Widget createMapView({
    required List<PinDto> pins,
    void Function(Coordinate coordinate, String? locationName)? onMapLongTapped,
    Function(PinDto)? onMarkerTapped,
    Function(PinDto)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  });
}
