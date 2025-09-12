import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view_builder.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';

void main() {
  group('PlaceholderMapViewBuilder', () {
    test('createMapViewでPlaceholderMapViewを作成する', () {
      final service = PlaceholderMapViewBuilder();
      final pins = <PinDto>[];

      final widget = service.createMapView(pins: pins);

      expect(widget, isA<PlaceholderMapView>());
    });

    test('コールバック関数を受け取るが使用しない', () {
      final service = PlaceholderMapViewBuilder();
      final pins = <PinDto>[];

      void onMapLongTapped(Location location) {}
      void onMarkerTapped(PinDto pin) {}
      void onMarkerDeleted(String pinId) {}

      final widget = service.createMapView(
        pins: pins,
        onMapLongTapped: onMapLongTapped,
        onMarkerTapped: onMarkerTapped,
        onMarkerDeleted: onMarkerDeleted,
      );

      expect(widget, isA<PlaceholderMapView>());
    });
  });
}
