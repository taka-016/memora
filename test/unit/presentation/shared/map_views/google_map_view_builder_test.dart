import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/presentation/shared/map_views/google_map_view_builder.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';

void main() {
  group('GoogleMapViewBuilder', () {
    test('createMapViewでGoogleMapViewを作成する', () {
      const service = GoogleMapViewBuilder();
      final pins = <PinDto>[];

      final widget = service.createMapView(pins: pins);

      expect(widget, isA<GoogleMapView>());
    });

    test('コールバック関数を正しく渡す', () {
      const service = GoogleMapViewBuilder();
      final pins = <PinDto>[];

      void onMapLongTapped(Coordinate coordinate) {}
      void onSearchedLocationSelected(LocationCandidateDto candidate) {}
      void onPinTapped(PinDto pin) {}
      void onPinDeleted(String pinId) {}

      final widget = service.createMapView(
        pins: pins,
        onMapLongTapped: onMapLongTapped,
        onSearchedLocationSelected: onSearchedLocationSelected,
        onPinTapped: onPinTapped,
        onPinDeleted: onPinDeleted,
      );

      expect(widget, isA<GoogleMapView>());
    });
  });
}
