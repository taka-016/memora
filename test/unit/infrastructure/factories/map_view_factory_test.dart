import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/factories/map_view_factory.dart';
import 'package:memora/infrastructure/services/google_map_view_service.dart';
import 'package:memora/infrastructure/services/placeholder_map_view_service.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:mockito/annotations.dart';
import 'map_view_factory_test.mocks.dart';

@GenerateMocks([CurrentLocationService])
void main() {
  group('MapViewFactory', () {
    late MockCurrentLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockCurrentLocationService();
    });

    test('GoogleMapTypeでGoogleMapViewServiceを作成する', () {
      final service = MapViewFactory.create(
        MapViewType.google,
        locationService: mockLocationService,
      );

      expect(service, isA<GoogleMapViewService>());
    });

    test('PlaceholderMapTypeでPlaceholderMapViewServiceを作成する', () {
      final service = MapViewFactory.create(
        MapViewType.placeholder,
        locationService: mockLocationService,
      );

      expect(service, isA<PlaceholderMapViewService>());
    });

    test('locationServiceなしでも作成できる', () {
      final googleService = MapViewFactory.create(MapViewType.google);
      final placeholderService = MapViewFactory.create(MapViewType.placeholder);

      expect(googleService, isA<GoogleMapViewService>());
      expect(placeholderService, isA<PlaceholderMapViewService>());
    });
  });
}
