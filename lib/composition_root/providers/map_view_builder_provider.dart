import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/map_view_factory.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';

final mapViewBuilderProvider = Provider<MapViewBuilder>((ref) {
  return MapViewFactory.create(ref.watch(appModeProvider));
});
