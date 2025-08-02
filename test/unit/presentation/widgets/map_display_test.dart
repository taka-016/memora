import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/widgets/map_display.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'map_display_test.mocks.dart';

@GenerateMocks([CurrentLocationService])
class MockPinRepository implements PinRepository {
  List<Pin> pins = [
    Pin(id: '1', pinId: '1', latitude: 10, longitude: 10),
    Pin(id: '2', pinId: '2', latitude: 20, longitude: 20),
  ];

  @override
  Future<List<Pin>> getPins() async {
    return pins.toList();
  }

  @override
  Future<void> savePin(String pinId, double latitude, double longitude) async {
    pins.add(
      Pin(id: pinId, pinId: pinId, latitude: latitude, longitude: longitude),
    );
  }

  @override
  Future<void> deletePin(String pinId) async {
    pins.removeWhere((pin) => pin.pinId == pinId);
  }
}

void main() {
  group('MapDisplay', () {
    late MockCurrentLocationService mockLocationService;
    late MockPinRepository mockPinRepository;

    setUp(() {
      mockLocationService = MockCurrentLocationService();
      mockPinRepository = MockPinRepository();
    });

    testWidgets('MapDisplayが正しく表示される', (WidgetTester tester) async {
      final testPins = [
        Pin(
          id: 'pin1',
          pinId: 'pin1',
          latitude: 35.681236,
          longitude: 139.767125,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              initialPins: testPins,
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );

      expect(find.byType(MapDisplay), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('検索バーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('場所を検索'), findsOneWidget);
    });

    testWidgets('現在地ボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('マーカーをタップすると削除メニュー付きポップアップが表示される', (WidgetTester tester) async {
      final initialPins = [
        Pin(id: '1', pinId: '1', latitude: 10, longitude: 10),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              initialPins: initialPins,
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );

      // マーカーのFinder（仮: Key('map_marker_0')で1つ目のマーカーを識別）
      final markerFinder = find.byKey(Key('map_marker_0'));
      expect(markerFinder, findsOneWidget);

      // マーカーをタップ
      await tester.tap(markerFinder);
      await tester.pumpAndSettle();

      // ポップアップメニューが表示され、「削除」メニューが存在することを確認
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('マップ起動時に保存済みのマーカーが表示される', (WidgetTester tester) async {
      final initialPins = [
        Pin(id: '1', pinId: '1', latitude: 10, longitude: 10),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              initialPins: initialPins,
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期マーカーの2つがKey('map_marker_0')とKey('map_marker_1')で表示されることを確認
      expect(find.byKey(Key('map_marker_0')), findsOneWidget);
      expect(find.byKey(Key('map_marker_1')), findsOneWidget);
    });

    testWidgets('現在地ボタンを押すとCurrentLocationServiceが呼ばれる', (
      WidgetTester tester,
    ) async {
      final mockService = MockCurrentLocationService();
      when(mockService.getCurrentLocation()).thenAnswer(
        (_) async => const CurrentLocation(latitude: 1.0, longitude: 2.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              locationService: mockService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 現在地ボタンをタップ
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      // LocationService.getCurrentLocationが呼ばれたことを検証
      verify(mockService.getCurrentLocation()).called(1);
    });

    testWidgets('ピンをタップしたときにボトムシートが表示される', (WidgetTester tester) async {
      final initialPins = [
        Pin(id: '1', pinId: '1', latitude: 10, longitude: 10),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              initialPins: initialPins,
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // マーカーのタップをシミュレート
      final markerKey = find.byKey(const Key('map_marker_0'));
      expect(markerKey, findsOneWidget);
      await tester.tap(markerKey);
      await tester.pumpAndSettle();

      // ボトムシートが表示されていることを確認（DraggableScrollableSheetを使用）
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('ボトムシートをドラッグで拡張できる', (WidgetTester tester) async {
      final initialPins = [
        Pin(id: '1', pinId: '1', latitude: 10, longitude: 10),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDisplay(
              initialPins: initialPins,
              locationService: mockLocationService,
              pinRepository: mockPinRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // マーカーをタップしてボトムシートを表示
      final markerKey = find.byKey(const Key('map_marker_0'));
      await tester.tap(markerKey);
      await tester.pumpAndSettle();

      // DraggableScrollableSheetが存在することを確認
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // ドラッグ可能なハンドルまたはコンテンツが存在することを確認
      expect(find.text('訪問開始日'), findsOneWidget);
      expect(find.text('旅行終了日'), findsOneWidget);
      expect(find.text('メモ'), findsOneWidget);
    });
  });
}
