import 'package:memora/domain/services/map/map_view_service.dart';
import 'package:memora/infrastructure/services/map/google_map_view_service.dart';
import 'package:memora/infrastructure/services/map/placeholder_map_view_service.dart';

enum MapViewType { google, placeholder }

class MapViewFactory {
  static MapViewService create(MapViewType type) {
    switch (type) {
      case MapViewType.google:
        return const GoogleMapViewService();
      case MapViewType.placeholder:
        return const PlaceholderMapViewService();
    }
  }
}
