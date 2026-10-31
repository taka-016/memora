import 'dart:math' as math;
import 'dart:convert';

import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/infrastructure/map_views/google_map_view.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'google_map_view_test.mocks.dart';

@GenerateMocks([
  GetCurrentLocationUsecase,
  SearchLocationsUsecase,
  GoogleMapController,
])
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

Widget _createApp(
  Widget child, {
  SearchLocationsUsecase? searchUsecase,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: [
      getCurrentLocationUsecaseProvider.overrideWithValue(
        _mockGetCurrentLocationUsecase(),
      ),
      searchLocationsUsecaseProvider.overrideWithValue(
        searchUsecase ?? _mockSearchLocationsUsecase(),
      ),
    ],
    child: MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('GoogleMapView', () {
    testWidgets('地図本体の配色もテーマの明暗変更に追従する', (tester) async {
      for (final brightness in [
        Brightness.light,
        Brightness.dark,
        Brightness.light,
      ]) {
        await tester.pumpWidget(
          _createApp(
            const GoogleMapView(locations: []),
            theme: ThemeData(brightness: brightness),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
        if (brightness == Brightness.dark) {
          expect(map.style, isNotNull);
          final rules = jsonDecode(map.style!) as List<dynamic>;
          expect(rules, isNotEmpty);
        } else {
          expect(map.style, isNull);
        }
      }
    });
    testWidgets('地図ボタン下の余白では背後の地図へタッチが届く', (tester) async {
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final mapRenderBox = tester.renderObject<RenderBox>(
        find.byType(GoogleMap),
      );

      for (final bearing in [0.0, 90.0]) {
        googleMap.onCameraMove!(
          CameraPosition(target: const LatLng(35, 139), bearing: bearing),
        );
        await tester.pump();
        final point = Offset(
          tester.getCenter(find.byIcon(Icons.my_location)).dx,
          tester.getBottomRight(find.byKey(const Key('map_view'))).dy - 32,
        );
        final hit = tester.hitTestOnBinding(point);

        expect(
          hit.path.map((entry) => entry.target),
          contains(mapRenderBox),
          reason: '標準ズームボタンが表示される右下領域への入力を遮らない',
        );
      }
    });

    testWidgets('回転中は北を指すコンパスが検索バーに重ならず現在地ボタンの上に表示される', (tester) async {
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.compassEnabled, isFalse);
      expect(find.byTooltip('北向きに戻す'), findsNothing);
      expect(googleMap.onCameraMove, isNotNull);

      for (final bearing in [90.0, 270.0, 359.0]) {
        googleMap.onCameraMove!(
          CameraPosition(target: const LatLng(35, 139), bearing: bearing),
        );
        await tester.pump();

        final compass = find.byTooltip('北向きに戻す');
        expect(compass, findsOneWidget);
        expect(
          tester.getRect(compass).bottom,
          lessThan(tester.getRect(find.byIcon(Icons.my_location)).top),
        );
        expect(
          tester
              .getRect(compass)
              .overlaps(tester.getRect(find.byType(TextField))),
          isFalse,
        );
        final needle = tester.widget<Transform>(
          find.byKey(const Key('map_compass_needle')),
        );
        final radians = bearing * math.pi / 180;
        expect(
          -needle.transform.storage[4],
          closeTo(-math.sin(radians), 0.000001),
        );
        expect(
          -needle.transform.storage[5],
          closeTo(-math.cos(radians), 0.000001),
        );
      }

      googleMap.onCameraMove!(const CameraPosition(target: LatLng(35, 139)));
      await tester.pump();
      expect(find.byTooltip('北向きに戻す'), findsNothing);
    });

    testWidgets('コンパスを押すと最新の表示位置とズームと傾きを保って北向きに戻す', (tester) async {
      final controller = MockGoogleMapController();
      when(controller.animateCamera(any)).thenAnswer((_) async {});
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.onMapCreated!(controller);
      await tester.pump();
      expect(googleMap.onCameraMove, isNotNull);

      googleMap.onCameraMove!(
        const CameraPosition(target: LatLng(35, 139), bearing: 90, zoom: 12),
      );
      await tester.pump();
      googleMap.onCameraMove!(
        const CameraPosition(
          target: LatLng(34, 135),
          bearing: 90,
          zoom: 18,
          tilt: 30,
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('北向きに戻す'));
      await tester.pump();

      final update =
          verify(controller.animateCamera(captureAny)).captured.single
              as CameraUpdate;
      expect(
        update.toJson(),
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: LatLng(34, 135), zoom: 18, tilt: 30),
        ).toJson(),
      );
    });

    for (final height in [280.0, 200.0]) {
      testWidgets('高さ${height.toInt()}の地図でもコンパスと検索欄と上部ツールバーが重ならず操作できる', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(800, height));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var groupSelectorTapped = false;
        final groupSelector = find.byKey(const Key('compact_group_selector'));
        await tester.pumpWidget(
          _createApp(
            GoogleMapView(
              locations: const [],
              topLeadingOverlay: TextButton(
                key: const Key('compact_group_selector'),
                onPressed: () => groupSelectorTapped = true,
                child: const Text('グループを選択'),
              ),
            ),
          ),
        );
        final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
        googleMap.onCameraMove!(
          const CameraPosition(target: LatLng(35, 139), bearing: 90),
        );
        await tester.pump();

        final compass = find.byTooltip('北向きに戻す');
        expect(
          tester
              .getRect(compass)
              .overlaps(tester.getRect(find.byType(TextField))),
          isFalse,
        );
        expect(
          tester.getRect(compass).overlaps(tester.getRect(groupSelector)),
          isFalse,
        );
        expect(
          tester.getRect(compass).bottom,
          lessThan(tester.getRect(find.byIcon(Icons.my_location)).top),
        );
        await tester.ensureVisible(groupSelector);
        await tester.pump();
        await tester.tap(groupSelector);
        await tester.pump();
        expect(groupSelectorTapped, isTrue);
        await tester.ensureVisible(find.byIcon(Icons.my_location));
        await tester.pump();
        expect(find.byIcon(Icons.my_location).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('狭い地図で検索候補が多くても候補選択と地図ボタンを操作できる', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 280));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final candidates = List.generate(
        6,
        (index) => LocationCandidateDto(
          name: '候補$index',
          address: '住所$index',
          coordinate: const Coordinate(latitude: 35, longitude: 139),
        ),
      );
      final searchUsecase = MockSearchLocationsUsecase();
      when(searchUsecase.execute(any)).thenAnswer((_) async => candidates);
      LocationCandidateDto? selected;
      await tester.pumpWidget(
        _createApp(
          GoogleMapView(
            locations: const [],
            onSearchedLocationSelected: (candidate) => selected = candidate,
          ),
          searchUsecase: searchUsecase,
        ),
      );
      tester.widget<GoogleMap>(find.byType(GoogleMap)).onCameraMove!(
        const CameraPosition(target: LatLng(35, 139), bearing: 90),
      );
      await tester.enterText(find.byType(TextField), '駅');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('北向きに戻す').hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.my_location));
      await tester.pump();
      expect(find.byIcon(Icons.my_location).hitTestable(), findsOneWidget);
      await tester.tap(find.text('候補0'));
      await tester.pump();
      expect(selected, candidates.first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GoogleMapViewが正しく表示される', (tester) async {
      await tester.pumpWidget(_createApp(const GoogleMapView(locations: [])));

      expect(find.byKey(const Key('map_view')), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('文字サイズを拡大しても検索とグループ選択を操作できる', (tester) async {
      var groupSelectorTapped = false;

      await tester.pumpWidget(
        _createApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: GoogleMapView(
              locations: const [],
              topLeadingOverlay: SizedBox(
                width: 160,
                child: TextButton(
                  key: const Key('test_group_selector'),
                  onPressed: () {
                    groupSelectorTapped = true;
                  },
                  child: const Text('グループを選択'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.byKey(const Key('test_group_selector')));
      await tester.pump();

      expect(groupSelectorTapped, isTrue);
      expect(tester.takeException(), isNull);
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
