import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/placeholder_map_view_service.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/presentation/widgets/placeholder_map_view.dart';

void main() {
  group('PlaceholderMapViewService', () {
    test('createMapViewでPlaceholderMapViewを作成する', () {
      final service = PlaceholderMapViewService();
      final pins = <Pin>[];

      final widget = service.createMapView(pins: pins);

      expect(widget, isA<PlaceholderMapView>());
    });

    test('コールバック関数を受け取るが使用しない', () {
      final service = PlaceholderMapViewService();
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

      expect(widget, isA<PlaceholderMapView>());
    });
  });
}
