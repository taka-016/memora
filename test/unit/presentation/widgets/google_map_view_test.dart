import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/widgets/google_map_view.dart';
import 'package:memora/presentation/widgets/pin_detail_bottom_sheet.dart';

void main() {
  group('GoogleMapView', () {
    testWidgets('GoogleMapViewが正しく表示される', (WidgetTester tester) async {
      const testPins = <Pin>[];

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

    testWidgets('ピンがマーカーとして表示される', (WidgetTester tester) async {
      final testPins = [
        const Pin(
          id: 'pin1',
          pinId: 'pin1',
          latitude: 35.681236,
          longitude: 139.767125,
        ),
        const Pin(
          id: 'pin2',
          pinId: 'pin2',
          latitude: 35.681236,
          longitude: 139.767125,
        ),
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
      Location? tappedLocation;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [],
                onMapLongTapped: (Location location) {
                  mapTapped = true;
                  tappedLocation = location;
                },
                onMarkerTapped: (Pin pin) {},
                onMarkerSaved: (Pin pin) {},
                onMarkerDeleted: (String pinId) {},
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
    testWidgets('マーカーをタップするとコールバック関数が呼ばれボトムシートが表示される', (
      WidgetTester tester,
    ) async {
      const testPin = Pin(
        id: 'pin1',
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      bool markerTapped = false;
      Pin? tappedPin;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onMarkerTapped: (Pin pin) {
                  markerTapped = true;
                  tappedPin = pin;
                },
              ),
            ),
          ),
        ),
      );

      // 初期状態ではボトムシートは非表示
      expect(find.text('削除'), findsNothing);

      // GoogleMapからマーカーを見つけてタップする
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markers = googleMap.markers;
      expect(markers.length, 1);

      // マーカーのonTapコールバックを実行
      final marker = markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // ボトムシートが表示されることを確認
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

      // コールバック関数が正しく呼ばれたことを確認
      expect(markerTapped, true);
      expect(tappedPin, testPin);
    });

    testWidgets('保存ボタンをタップするとonMarkerSavedコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      const testPin = Pin(
        id: 'pin1',
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      bool markerSaved = false;
      Pin? savedPin;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onMarkerSaved: (Pin pin) {
                  markerSaved = true;
                  savedPin = pin;
                },
              ),
            ),
          ),
        ),
      );

      // マーカーをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // 保存ボタンを画面内に表示させてからタップ
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // コールバック関数が正しく呼ばれたことを確認
      expect(markerSaved, true);
      expect(savedPin?.pinId, testPin.pinId);
      expect(savedPin?.latitude, testPin.latitude);
      expect(savedPin?.longitude, testPin.longitude);
    });

    testWidgets('削除ボタンをタップするとonMarkerDeletedコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      const testPin = Pin(
        id: 'pin1',
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      bool markerDeleted = false;
      String? deletedPinId;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onMarkerDeleted: (String pinId) {
                  markerDeleted = true;
                  deletedPinId = pinId;
                },
              ),
            ),
          ),
        ),
      );

      // マーカーをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // 削除ボタンを画面内に表示させてからタップ
      await tester.ensureVisible(find.text('削除'));
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // コールバック関数が正しく呼ばれたことを確認
      expect(markerDeleted, true);
      expect(deletedPinId, testPin.pinId);
    });

    testWidgets('ボトムシートが表示されて保存ボタンが存在する', (WidgetTester tester) async {
      const testPin = Pin(
        id: 'pin1',
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

      // マーカーをタップしてボトムシートを表示
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final marker = googleMap.markers.first;
      marker.onTap!();
      await tester.pumpAndSettle();

      // ボトムシートが表示されて保存ボタンが存在することを確認
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
    });
  });
}
