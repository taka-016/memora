import 'package:flutter/material.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/entities/pin.dart';

abstract class MapViewBuilder {
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(Pin)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    Pin? selectedPin,
  });
}
