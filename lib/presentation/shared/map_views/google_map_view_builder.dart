import 'package:flutter/material.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';

class GoogleMapViewBuilder implements MapViewBuilder {
  const GoogleMapViewBuilder();

  @override
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(Pin)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    Pin? selectedPin,
  }) {
    return GoogleMapView(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onMarkerTapped: onMarkerTapped,
      onMarkerUpdated: onMarkerUpdated,
      onMarkerDeleted: onMarkerDeleted,
      selectedPin: selectedPin,
    );
  }
}
