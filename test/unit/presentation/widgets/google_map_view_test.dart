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

    testWidgets('コールバック関数が正しく設定される', (WidgetTester tester) async {
      bool mapTapped = false;
      bool pinTapped = false;
      bool pinDeleted = false;

      const testPin = Pin(
        id: 'pin1',
        pinId: 'pin1',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleMapView(
                pins: const [testPin],
                onMapLongTapped: (Location location) {
                  mapTapped = true;
                },
                onMarkerTapped: (Pin pin) {
                  pinTapped = true;
                },
                onMarkerDeleted: (String pinId) {
                  pinDeleted = true;
                },
              ),
            ),
          ),
        ),
      );

      // GoogleMapウィジェットが表示されていることを確認
      expect(find.byType(GoogleMap), findsOneWidget);

      // コールバック関数の初期状態を確認
      expect(mapTapped, false);
      expect(pinTapped, false);
      expect(pinDeleted, false);
    });
    testWidgets('マーカーをタップするとボトムシートが表示される', (WidgetTester tester) async {
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
