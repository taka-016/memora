import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/presentation/shared/map_views/google_map_view_builder.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view_builder.dart';

enum MapViewType { google, placeholder }

class MapViewFactory {
  static MapViewBuilder create(MapViewType type) {
    switch (type) {
      case MapViewType.google:
        return const GoogleMapViewBuilder();
      case MapViewType.placeholder:
        return const PlaceholderMapViewBuilder();
    }
  }
}
