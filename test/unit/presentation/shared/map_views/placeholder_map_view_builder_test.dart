import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view_builder.dart';

void main() {
  group('PlaceholderMapViewBuilder', () {
    test('createMapViewでPlaceholderMapViewを作成する', () {
      const service = PlaceholderMapViewBuilder();
      final locations = <LocationDto>[];

      final widget = service.createMapView(locations: locations);

      expect(widget, isA<PlaceholderMapView>());
    });

    test('コールバック関数を受け取るが使用しない', () {
      const service = PlaceholderMapViewBuilder();
      final locations = <LocationDto>[];

      void onMapLongTapped(Coordinate coordinate) {}
      void onSearchedLocationSelected(LocationCandidateDto candidate) {}
      void onLocationTapped(LocationDto location) {}

      final widget = service.createMapView(
        locations: locations,
        onMapLongTapped: onMapLongTapped,
        onSearchedLocationSelected: onSearchedLocationSelected,
        onLocationTapped: onLocationTapped,
      );

      expect(widget, isA<PlaceholderMapView>());
    });
  });
}
