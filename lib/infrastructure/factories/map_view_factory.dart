import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/infrastructure/map_views/google_map_view_builder.dart';
import 'package:memora/infrastructure/map_views/unavailable_map_view_builder.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';

class MapViewFactory {
  static MapViewBuilder create(AppMode mode) => switch (mode) {
    AppMode.online => const GoogleMapViewBuilder(),
    AppMode.offline => UnavailableMapViewBuilder(
      AppCapabilities.forMode(mode).availability(AppFeature.maps).reason!,
    ),
  };
}
