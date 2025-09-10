import 'package:flutter/material.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';

class PlaceholderMapViewBuilder implements MapViewBuilder {
  const PlaceholderMapViewBuilder();

  @override
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(Pin)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    Pin? selectedPin,
  }) {
    return const PlaceholderMapView();
  }
}
