import 'package:flutter/material.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';

abstract class MapViewService {
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(String)? onMarkerDeleted,
  });
}
