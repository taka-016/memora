import 'package:memora/domain/services/map_view_service.dart';
import 'package:memora/infrastructure/services/google_map_view_service.dart';
import 'package:memora/infrastructure/services/placeholder_map_view_service.dart';

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
