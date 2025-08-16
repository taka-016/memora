import 'package:memora/domain/services/map_view_service.dart';
import 'package:memora/infrastructure/services/google_map_view_service.dart';
import 'package:memora/infrastructure/services/placeholder_map_view_service.dart';

/// 地図ビューの種類
enum MapViewType { google, placeholder }

/// 地図ビューサービスを生成するファクトリクラス
class MapViewFactory {
  /// 指定された地図タイプに応じた地図ビューサービスを生成する
  static MapViewService create(MapViewType type) {
    switch (type) {
      case MapViewType.google:
        return const GoogleMapViewService();
      case MapViewType.placeholder:
        return const PlaceholderMapViewService();
    }
  }
}
