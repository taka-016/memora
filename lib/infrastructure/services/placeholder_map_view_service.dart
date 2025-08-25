import 'package:flutter/material.dart';
import 'package:memora/domain/services/map_view_service.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/widgets/placeholder_map_view.dart';

/// テスト用のプレースホルダー地図ビューサービスの実装
class PlaceholderMapViewService implements MapViewService {
  const PlaceholderMapViewService();

  @override
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(Pin)? onMarkerSaved,
    Function(String)? onMarkerDeleted,
    Pin? selectedPin,
  }) {
    return const PlaceholderMapView();
  }
}
