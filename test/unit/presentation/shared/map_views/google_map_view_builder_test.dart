import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/map_views/google_map_view_builder.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';

void main() {
  group('GoogleMapViewBuilder', () {
    test('createMapViewでGoogleMapViewを作成する', () {
      const service = GoogleMapViewBuilder();
      final pins = <Pin>[];

      final widget = service.createMapView(pins: pins);

      expect(widget, isA<GoogleMapView>());
    });

    test('コールバック関数を正しく渡す', () {
      const service = GoogleMapViewBuilder();
      final pins = <Pin>[];

      void onMapLongTapped(Location location) {}
      void onMarkerTapped(Pin pin) {}
      void onMarkerDeleted(String pinId) {}

      final widget = service.createMapView(
        pins: pins,
        onMapLongTapped: onMapLongTapped,
        onMarkerTapped: onMarkerTapped,
        onMarkerDeleted: onMarkerDeleted,
      );

      expect(widget, isA<GoogleMapView>());
    });
  });
}
