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

    testWidgets('詳細が非表示の場合は現在地ボタンを地図の下端付近に表示する', (tester) async {
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));

      final locationButtonPosition = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Positioned),
        ),
      );

      expect(locationButtonPosition.bottom, 20);
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
            highlightSelectedLocation: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markersById = {
        for (final marker in googleMap.markers) marker.markerId.value: marker,
      };

      expect(
        markersById['location1']!.icon.toJson(),
        BitmapDescriptor.defaultMarker.toJson(),
      );
      expect(
        markersById['location2']!.icon.toJson().toString(),
        contains('[bytes'),
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
      expect(find.text('35.6812, 139.7671'), findsNothing);
    });

    testWidgets('外部指定した高さで選択中locationの軽量ボトムシートを表示する', (tester) async {
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
            locationDetailBottomSheetHeight: 220,
          ),
        ),
      );
      await tester.pump();

      expect(
        tester
            .getSize(find.byKey(const Key('location_detail_bottom_sheet')))
            .height,
        220,
      );
      final locationButtonPosition = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Positioned),
        ),
      );
      expect(locationButtonPosition.bottom, 240);
    });

    testWidgets('ボトムシートの前後ボタンで取得順のピンへ循環移動する', (tester) async {
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 35.6812,
          longitude: 139.7671,
          name: '東京駅',
        ),
        LocationDto(
          id: 'location2',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 35.682,
          longitude: 139.768,
          name: '上野駅',
        ),
        LocationDto(
          id: 'location3',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 35.683,
          longitude: 139.769,
          name: '品川駅',
        ),
      ];
      final tappedLocationIds = <String>[];

      await tester.pumpWidget(
        _createApp(
          GoogleMapView(
            locations: locations,
            selectedLocation: locations.first,
            onLocationTapped: (location) => tappedLocationIds.add(location.id),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('東京駅'), findsOneWidget);

      await tester.tap(find.byKey(const Key('location_detail_next_button')));
      await tester.pump();

      expect(find.text('上野駅'), findsOneWidget);
      expect(tappedLocationIds.last, 'location2');

      await tester.tap(
        find.byKey(const Key('location_detail_previous_button')),
      );
      await tester.pump();

      expect(find.text('東京駅'), findsOneWidget);
      expect(tappedLocationIds.last, 'location1');

      await tester.tap(
        find.byKey(const Key('location_detail_previous_button')),
      );
      await tester.pump();

      expect(find.text('品川駅'), findsOneWidget);
      expect(tappedLocationIds.last, 'location3');

      await tester.tap(find.byKey(const Key('location_detail_next_button')));
      await tester.pump();

      expect(find.text('東京駅'), findsOneWidget);
      expect(tappedLocationIds.last, 'location1');
    });

    testWidgets('ピン選択時の詳細表示を差し替えられる', (tester) async {
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
          GoogleMapView(
            locations: const [location],
            selectedLocation: location,
            locationDetailBuilder:
                (location, onClose, {onPreviousLocation, onNextLocation}) {
                  return Text('詳細: ${location.name}');
                },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('詳細: 東京駅'), findsOneWidget);
      expect(find.byType(LocationDetailBottomSheet), findsNothing);
    });
  });
}
