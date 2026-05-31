import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';
import 'package:memora/presentation/shared/map_views/google_map_view_builder.dart';

void main() {
  group('GoogleMapViewBuilder', () {
    test('createMapViewでGoogleMapViewを作成する', () {
      const service = GoogleMapViewBuilder();
      final locations = <LocationDto>[];

      final widget = service.createMapView(locations: locations);

      expect(widget, isA<GoogleMapView>());
    });

    test('locations用のコールバックを渡せる', () {
      const service = GoogleMapViewBuilder();
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

      expect(widget, isA<GoogleMapView>());
    });
  });
}
