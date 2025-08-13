import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/widgets/google_map_view.dart';
import 'package:mockito/annotations.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'google_map_view_test.mocks.dart';

@GenerateMocks([CurrentLocationService])
void main() {
  group('GoogleMapView', () {
    late MockCurrentLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockCurrentLocationService();
    });

    testWidgets('GoogleMapViewが正しく表示される', (WidgetTester tester) async {
      const testPins = <Pin>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleMapView(
              pins: testPins,
              locationService: mockLocationService,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('map_view')), findsOneWidget);
    });

    testWidgets('検索バーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleMapView(
              pins: const [],
              locationService: mockLocationService,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('現在地ボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleMapView(
              pins: const [],
              locationService: mockLocationService,
            ),
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
        MaterialApp(
          home: Scaffold(
            body: GoogleMapView(
              pins: testPins,
              locationService: mockLocationService,
            ),
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
        MaterialApp(
          home: Scaffold(
            body: GoogleMapView(
              pins: const [testPin],
              locationService: mockLocationService,
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
        MaterialApp(
          home: Scaffold(
            body: GoogleMapView(
              pins: const [testPin],
              locationService: mockLocationService,
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
    });
  });
}
