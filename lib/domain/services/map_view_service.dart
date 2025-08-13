import 'package:flutter/material.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';

/// 地図ビュー表示のためのサービスインターフェース
abstract class MapViewService {
  /// 地図ビューウィジェットを作成する
  Widget createMapView({
    required List<Pin> pins,
    Function(Location)? onMapLongTapped,
    Function(Pin)? onMarkerTapped,
    Function(String)? onMarkerDeleted,
  });
}
