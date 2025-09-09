import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/factories/map_view_factory.dart';
import 'package:memora/infrastructure/services/map/google_map_view_service.dart';
import 'package:memora/infrastructure/services/map/placeholder_map_view_service.dart';

void main() {
  group('MapViewFactory', () {
    test('GoogleMapTypeでGoogleMapViewServiceを作成する', () {
      final service = MapViewFactory.create(MapViewType.google);

      expect(service, isA<GoogleMapViewService>());
    });

    test('PlaceholderMapTypeでPlaceholderMapViewServiceを作成する', () {
      final service = MapViewFactory.create(MapViewType.placeholder);

      expect(service, isA<PlaceholderMapViewService>());
    });
  });
}
