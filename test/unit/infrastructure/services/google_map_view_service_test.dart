import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/google_map_view_service.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/presentation/widgets/google_map_view.dart';
import 'package:mockito/annotations.dart';
import 'google_map_view_service_test.mocks.dart';

@GenerateMocks([CurrentLocationService])
void main() {
  group('GoogleMapViewService', () {
    late MockCurrentLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockCurrentLocationService();
    });

    test('createMapViewでGoogleMapViewを作成する', () {
      final service = GoogleMapViewService(
        locationService: mockLocationService,
      );
      final pins = <Pin>[];

      final widget = service.createMapView(pins: pins);

      expect(widget, isA<GoogleMapView>());
    });

    test('コールバック関数を正しく渡す', () {
      final service = GoogleMapViewService();
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
