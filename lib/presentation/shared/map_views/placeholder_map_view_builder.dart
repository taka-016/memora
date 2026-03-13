import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';

class PlaceholderMapViewBuilder implements MapViewBuilder {
  const PlaceholderMapViewBuilder();

  @override
  Widget createMapView({
    required List<PinDto> pins,
    void Function(Coordinate coordinate, String? locationName)? onMapLongTapped,
    Function(PinDto)? onMarkerTapped,
    Function(PinDto)? onMarkerUpdated,
    Function(String)? onMarkerDeleted,
    PinDto? selectedPin,
    bool isReadOnly = false,
  }) {
    return const PlaceholderMapView();
  }
}
