import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'google_map_view_test.mocks.dart';

@GenerateMocks([GetCurrentLocationUsecase, SearchLocationsUsecase])
MockGetCurrentLocationUsecase _mockGetCurrentLocationUsecase([
  Coordinate? coordinate,
]) {
  final usecase = MockGetCurrentLocationUsecase();
  when(usecase.execute()).thenAnswer((_) async => coordinate);
  return usecase;
}

MockSearchLocationsUsecase _mockSearchLocationsUsecase() {
  final usecase = MockSearchLocationsUsecase();
  when(usecase.execute(any)).thenAnswer((_) async => const []);
  return usecase;
}

Widget _createApp(Widget child) {
  return ProviderScope(
    overrides: [
      getCurrentLocationUsecaseProvider.overrideWithValue(
        _mockGetCurrentLocationUsecase(),
      ),
      searchLocationsUsecaseProvider.overrideWithValue(
        _mockSearchLocationsUsecase(),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('GoogleMapView', () {
    testWidgets('GoogleMapViewが正しく表示される', (tester) async {
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));

      expect(find.byKey(const Key('map_view')), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('locationがない場合、デフォルト位置を使用する', (tester) async {
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      expect(initialPosition.target.latitude, 35.681236);
      expect(initialPosition.target.longitude, 139.767125);
    });

    testWidgets('最初のlocationを初期位置に使用する', (tester) async {
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          name: '大阪駅',
        ),
      ];

      await tester.pumpWidget(
        _createApp(const GoogleMapView(locations: locations)),
      );

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      expect(initialPosition.target.latitude, 34.6937);
      expect(initialPosition.target.longitude, 135.5023);
    });

    testWidgets('選択中locationがある場合は選択中locationを初期位置に使用する', (tester) async {
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          name: '大阪駅',
        ),
        LocationDto(
          id: 'location2',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 26.217,
          longitude: 127.719,
          name: '首里城',
        ),
      ];

      await tester.pumpWidget(
        _createApp(
          GoogleMapView(locations: locations, selectedLocation: locations.last),
        ),
      );

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      expect(initialPosition.target.latitude, 26.217);
      expect(initialPosition.target.longitude, 127.719);
    });

    testWidgets('location.idをMarkerIdに使用する', (tester) async {
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 35.6812,
          longitude: 139.7671,
        ),
      ];

      await tester.pumpWidget(
        _createApp(const GoogleMapView(locations: locations)),
      );

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));

      expect(googleMap.markers.single.markerId, const MarkerId('location1'));
    });

    testWidgets('選択中locationは赤色、それ以外は灰色のマーカーで表示する', (tester) async {
      const selectedLocation = LocationDto(
        id: 'location1',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 35.6812,
        longitude: 139.7671,
      );
      const otherLocation = LocationDto(
        id: 'location2',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 35.682,
        longitude: 139.768,
      );

      await tester.pumpWidget(
        _createApp(
          const GoogleMapView(
            locations: [selectedLocation, otherLocation],
            selectedLocation: selectedLocation,
          ),
        ),
      );

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markersById = {
        for (final marker in googleMap.markers) marker.markerId.value: marker,
      };

      expect(
        markersById['location1']!.icon.toJson(),
        BitmapDescriptor.defaultMarker.toJson(),
      );
      expect(
        markersById['location2']!.icon.toJson(),
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ).toJson(),
      );
    });

    testWidgets('選択中locationの軽量ボトムシートを表示する', (tester) async {
      const location = LocationDto(
        id: 'location1',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 35.6812,
        longitude: 139.7671,
        name: '東京駅',
      );

      await tester.pumpWidget(
        _createApp(
          const GoogleMapView(
            locations: [location],
            selectedLocation: location,
            isReadOnly: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LocationDetailBottomSheet), findsOneWidget);
      expect(find.text('東京駅'), findsOneWidget);
    });
  });
}
