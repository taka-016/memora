import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';

abstract class MapViewBuilder {
  Widget createMapView({
    required List<PinDto> pins,
    void Function(double latitude, double longitude)? onMapLongTapped,
    void Function(PinDto)? onMarkerTapped,
    void Function(PinDto)? onMarkerUpdated,
    void Function(String)? onMarkerDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  });
}
