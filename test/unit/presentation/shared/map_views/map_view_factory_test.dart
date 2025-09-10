import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';
import 'package:memora/presentation/shared/map_views/google_map_view_builder.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view_builder.dart';

void main() {
  group('MapViewFactory', () {
    test('GoogleMapTypeでGoogleMapViewBuilderを作成する', () {
      final service = MapViewFactory.create(MapViewType.google);

      expect(service, isA<GoogleMapViewBuilder>());
    });

    test('PlaceholderMapTypeでPlaceholderMapViewBuilderを作成する', () {
      final service = MapViewFactory.create(MapViewType.placeholder);

      expect(service, isA<PlaceholderMapViewBuilder>());
    });
  });
}
