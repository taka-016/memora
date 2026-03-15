import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/presentation/notifiers/coordinate_notifier.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';

class MockLocationService implements CurrentLocationService {
  final Coordinate? _coordinate;

  MockLocationService([this._coordinate]);

  @override
  Future<Coordinate?> getCurrentLocation() async {
    return _coordinate;
  }
}

class MockLocationSearchService implements LocationSearchService {
  MockLocationSearchService(this._candidates);

  final List<LocationCandidateDto> _candidates;

  @override
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword) async {
    return _candidates;
  }
}

void main() {
  group('GoogleMapView', () {
    testWidgets('GoogleMapViewが正しく表示される', (WidgetTester tester) async {
      const testPins = <PinDto>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: testPins)),
          ),
        ),
      );

      expect(find.byKey(const Key('map_view')), findsOneWidget);
    });

    testWidgets('検索バーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [])),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('現在地ボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [])),
          ),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('ピンもcoordinateProviderもない場合、デフォルト位置（東京駅）を使用する', (
      WidgetTester tester,
    ) async {
      // coordinateProviderにnullを設定
      final container = ProviderContainer(
        overrides: [
          currentLocationServiceProvider.overrideWithValue(
            MockLocationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [])),
          ),
        ),
      );

      // GoogleMapウィジェットを取得してinitialCameraPositionを確認
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      // デフォルト位置（東京駅）を確認
      expect(initialPosition.target.latitude, 35.681236);
      expect(initialPosition.target.longitude, 139.767125);
    });

    testWidgets('ピンがない場合、coordinateProviderの位置を使用する', (
      WidgetTester tester,
    ) async {
      // coordinateProviderに大阪の位置を設定
      final testLocation = Coordinate(
        latitude: 34.693738,
        longitude: 135.502165,
      );
      final container = ProviderContainer(
        overrides: [
          currentLocationServiceProvider.overrideWithValue(
            MockLocationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final coordinateNotifier = container.read(coordinateProvider.notifier);
      coordinateNotifier.setCoordinate(testLocation);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [])),
          ),
        ),
      );

      // GoogleMapウィジェットを取得してinitialCameraPositionを確認
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      // coordinateProviderの位置を確認
      expect(initialPosition.target.latitude, 34.693738);
      expect(initialPosition.target.longitude, 135.502165);
    });

    testWidgets('ピンがある場合、1件目のピンの位置を使用する', (WidgetTester tester) async {
      // 名古屋と京都のピンを作成（名古屋が1件目）
      final testPins = [
        const PinDto(
          pinId: 'pin1',
          latitude: 35.170915, // 名古屋
          longitude: 136.881537,
        ),
        const PinDto(
          pinId: 'pin2',
          latitude: 35.011635, // 京都
          longitude: 135.768029,
        ),
      ];

      // coordinateProviderにも位置を設定（こちらは使われない）
      final testLocation = Coordinate(
        latitude: 34.693738,
        longitude: 135.502165,
      );
      final container = ProviderContainer(
        overrides: [
          currentLocationServiceProvider.overrideWithValue(
            MockLocationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final coordinateNotifier = container.read(coordinateProvider.notifier);
      coordinateNotifier.setCoordinate(testLocation);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: testPins)),
          ),
        ),
      );

      // GoogleMapウィジェットを取得してinitialCameraPositionを確認
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      // 1件目のピン（名古屋）の位置を確認
      expect(initialPosition.target.latitude, 35.170915);
      expect(initialPosition.target.longitude, 136.881537);
    });

    testWidgets('ピンが地図上に表示される', (WidgetTester tester) async {
      final testPins = [
        const PinDto(pinId: 'pin1', latitude: 35.681236, longitude: 139.767125),
        const PinDto(pinId: 'pin2', latitude: 35.681236, longitude: 139.767125),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: testPins)),
          ),
        ),
      );

      // GoogleMapウィジェットが表示されていることを確認
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('マップの長押しでコールバック関数が呼ばれる', (WidgetTester tester) async {
      bool mapTapped = false;
      Coordinate? tappedLocation;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [],
                onMapLongTapped: (Coordinate coordinate) {
                  mapTapped = true;
                  tappedLocation = coordinate;
                },
                onPinTapped: (PinDto pin) {},
                onPinUpdated: (PinDto pin) {},
                onPinDeleted: (String pinId) {},
              ),
            ),
          ),
        ),
      );

      // GoogleMapウィジェットを取得
      final googleMapFinder = find.byType(GoogleMap);
      expect(googleMapFinder, findsOneWidget);

      // GoogleMapウィジェットからonLongPressを実行
      final googleMap = tester.widget<GoogleMap>(googleMapFinder);
      const testLatLng = LatLng(35.681236, 139.767125);

      // onLongPressコールバックを直接呼び出してテスト
      googleMap.onLongPress!(testLatLng);

      // コールバック関数が正しく呼ばれたことを確認
      expect(mapTapped, true);
      expect(tappedLocation?.latitude, 35.681236);
      expect(tappedLocation?.longitude, 139.767125);
    });

    testWidgets('検索結果を選択すると検索選択コールバックが呼ばれる', (WidgetTester tester) async {
      LocationCandidateDto? selectedCandidate;

      final searchCandidates = [
        const LocationCandidateDto(
          name: '首里城',
          address: '沖縄県那覇市首里金城町1-2',
          coordinate: Coordinate(latitude: 26.2173, longitude: 127.7190),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [],
                locationSearchService: MockLocationSearchService(
                  searchCandidates,
                ),
                onSearchedLocationSelected: (candidate) {
                  selectedCandidate = candidate;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '首里城');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '首里城'));
      await tester.pumpAndSettle();

      expect(selectedCandidate, equals(searchCandidates.first));
    });

    testWidgets('検索サービス未指定時でも再ビルドで同じインスタンスを使い回す', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [])),
          ),
        ),
      );

      final firstSearchBar = tester.widget<CustomSearchBar>(
        find.byType(CustomSearchBar),
      );
      final firstService = firstSearchBar.locationSearchService;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [])),
          ),
        ),
      );

      final secondSearchBar = tester.widget<CustomSearchBar>(
        find.byType(CustomSearchBar),
      );
      final secondService = secondSearchBar.locationSearchService;

      expect(firstService, isNotNull);
      expect(identical(secondService, firstService), isTrue);
    });

    testWidgets('ピンをタップするとコールバック関数が呼ばれボトムシートが表示される', (
      WidgetTester tester,
    ) async {
      const testPin = PinDto(
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      bool pinTapped = false;
      PinDto? tappedPin;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onPinTapped: (PinDto pin) {
                  pinTapped = true;
                  tappedPin = pin;
                },
              ),
            ),
          ),
        ),
      );

      // 初期状態ではボトムシートは非表示
      expect(find.text('削除'), findsNothing);

      // GoogleMapからピンを見つけてタップする
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markers = googleMap.markers;
      expect(markers.length, 1);

      // ピンのonTapコールバックを実行
      final marker = markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // ボトムシートが表示されることを確認
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);

      // コールバック関数が正しく呼ばれたことを確認
      expect(pinTapped, true);
      expect(tappedPin, testPin);
    });

    testWidgets('更新ボタンをタップするとonPinUpdatedコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      const testPin = PinDto(
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      bool pinUpdated = false;
      PinDto? updatedPin;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onPinUpdated: (PinDto pin) {
                  pinUpdated = true;
                  updatedPin = pin;
                },
              ),
            ),
          ),
        ),
      );

      // ピンをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // 更新ボタンを画面内に表示させてからタップ
      await tester.ensureVisible(find.text('更新'));
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // コールバック関数が正しく呼ばれたことを確認
      expect(pinUpdated, true);
      expect(updatedPin?.pinId, testPin.pinId);
      expect(updatedPin?.latitude, testPin.latitude);
      expect(updatedPin?.longitude, testPin.longitude);
    });

    testWidgets('削除ボタンをタップするとonPinDeletedコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      const testPin = PinDto(
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      bool pinDeleted = false;
      String? deletedPinId;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onPinDeleted: (String pinId) {
                  pinDeleted = true;
                  deletedPinId = pinId;
                },
              ),
            ),
          ),
        ),
      );

      // ピンをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // 削除ボタンを画面内に表示させてからタップ
      await tester.ensureVisible(find.text('削除'));
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // コールバック関数が正しく呼ばれたことを確認
      expect(pinDeleted, true);
      expect(deletedPinId, testPin.pinId);
    });

    testWidgets('ボトムシートが表示されて更新ボタンが存在する', (WidgetTester tester) async {
      const testPin = PinDto(
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [testPin])),
          ),
        ),
      );

      // ピンをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // ボトムシートが表示されて更新ボタンが存在することを確認
      expect(find.text('更新'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
    });

    testWidgets('ボトムシートが開いている状態で別のピンをタップすると、ボトムシートの内容が更新される', (
      WidgetTester tester,
    ) async {
      // 異なるメモを持つ2つのピンを準備
      const pin1 = PinDto(
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
        visitMemo: 'ピン1のメモ',
      );
      const pin2 = PinDto(
        pinId: 'pin2',
        latitude: 35.690000,
        longitude: 139.770000,
        visitMemo: 'ピン2のメモ',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GoogleMapView(pins: const [pin1, pin2])),
          ),
        ),
      );

      // GoogleMapからピンを取得
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markers = googleMap.markers.toList();
      expect(markers.length, 2);

      // 最初のピンをタップしてボトムシートを表示
      final marker1 = markers[0];
      marker1.onTap!();
      await tester.pumpAndSettle();

      // ボトムシートが表示され、1つ目のピンの内容が表示されていることを確認
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
      expect(find.text('ピン1のメモ'), findsOneWidget);

      // 2つ目のピンをタップ
      final marker2 = markers[1];
      marker2.onTap!();
      await tester.pumpAndSettle();

      // ボトムシートの内容が2つ目のピンに更新されていることを確認
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
      expect(find.text('ピン1のメモ'), findsNothing);
      expect(find.text('ピン2のメモ'), findsOneWidget);
    });

    testWidgets('isReadOnlyがtrueの場合、全ての編集機能が無効化される', (
      WidgetTester tester,
    ) async {
      const testPin = PinDto(
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
        locationName: '東京駅',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(pins: const [testPin], isReadOnly: true),
            ),
          ),
        ),
      );

      // ピンをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // ボトムシート自体は表示される
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);

      // 更新・削除ボタンが表示されない
      expect(find.text('更新'), findsNothing);
      expect(find.text('削除'), findsNothing);

      // 場所名の再取得ボタンは表示されない
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });
}
