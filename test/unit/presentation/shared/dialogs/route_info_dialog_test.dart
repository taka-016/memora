import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/domain/value_objects/travel_mode.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog.dart';

class FakeRouteInfoService implements RouteInfoService {
  final List<_RouteRequest> _requests = [];
  final Map<String, RouteSegmentDetail> responses;

  FakeRouteInfoService({required this.responses});

  int get callCount => _requests.length;

  @override
  Future<RouteSegmentDetail> fetchRoute({
    required Location origin,
    required Location destination,
    required TravelMode travelMode,
  }) async {
    _requests.add(
      _RouteRequest(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
      ),
    );
    final key =
        '${origin.latitude},${origin.longitude}->${destination.latitude},${destination.longitude}-$travelMode';
    return responses[key] ?? const RouteSegmentDetail.empty();
  }
}

class _RouteRequest {
  final Location origin;
  final Location destination;
  final TravelMode travelMode;

  _RouteRequest({
    required this.origin,
    required this.destination,
    required this.travelMode,
  });
}

void main() {
  final pins = [
    PinDto(
      pinId: 'pin-1',
      latitude: 35.0,
      longitude: 135.0,
      locationName: '京都駅',
      visitStartDate: DateTime(2024, 1, 1),
    ),
    PinDto(
      pinId: 'pin-2',
      latitude: 35.1,
      longitude: 135.1,
      locationName: '清水寺',
      visitEndDate: DateTime(2024, 1, 2),
    ),
    const PinDto(
      pinId: 'pin-3',
      latitude: 35.2,
      longitude: 135.2,
      locationName: '銀閣寺',
    ),
  ];

  Future<void> pumpRouteInfoDialog(
    WidgetTester tester, {
    RouteInfoService? service,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => RouteInfoDialog(
                        pins: pins,
                        routeInfoService: service,
                        isTestEnvironment: true,
                      ),
                    );
                  },
                  child: const Text('開く'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
  }

  group('RouteInfoDialog', () {
    testWidgets('ピンのリストはlocationNameのみ表示すること', (tester) async {
      await pumpRouteInfoDialog(tester);

      expect(find.text('京都駅'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('清水寺'),
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -200),
      );
      expect(find.text('清水寺'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('銀閣寺'),
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -200),
      );
      expect(find.text('銀閣寺'), findsOneWidget);

      expect(find.textContaining('2024'), findsNothing);
    });

    testWidgets('移動手段プルダウンの初期値が自動車であること', (tester) async {
      await pumpRouteInfoDialog(tester);

      final dropdowns = find.byKey(const Key('route_segment_mode_0'));
      expect(dropdowns, findsOneWidget);
      expect(
        find.descendant(of: dropdowns, matching: find.text('自動車')),
        findsOneWidget,
      );
    });

    testWidgets('ピンをタップすると選択状態になりハイライトされること', (tester) async {
      await pumpRouteInfoDialog(tester);

      final pinTileFinder = find.byKey(const Key('route_info_pin_tile_pin-1'));
      await tester.tap(pinTileFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(RouteInfoDialog)) as RouteInfoDialogState;
      expect(state.selectedPinIndex, 0);

      final listTile = tester.widget<ListTile>(pinTileFinder);
      expect(listTile.selected, isTrue);
    });

    testWidgets('経路検索ボタンをタップすると各区間の経路取得が呼び出されること', (tester) async {
      final fakeService = FakeRouteInfoService(
        responses: {
          '35.0,135.0->35.1,135.1-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.0, longitude: 135.0),
              Location(latitude: 35.05, longitude: 135.05),
              Location(latitude: 35.1, longitude: 135.1),
            ],
            distanceMeters: 0,
            durationSeconds: 0,
            instructions: const [],
          ),
          '35.1,135.1->35.2,135.2-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.1, longitude: 135.1),
              Location(latitude: 35.15, longitude: 135.15),
              Location(latitude: 35.2, longitude: 135.2),
            ],
            distanceMeters: 0,
            durationSeconds: 0,
            instructions: const [],
          ),
        },
      );

      await pumpRouteInfoDialog(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      expect(fakeService.callCount, 2);

      final state =
          tester.state(find.byType(RouteInfoDialog)) as RouteInfoDialogState;
      expect(state.segmentDetails.length, 2);
    });

    testWidgets('経路検索後に距離と時間および経路案内を折りたたみ表示できること', (tester) async {
      final fakeService = FakeRouteInfoService(
        responses: {
          '35.0,135.0->35.1,135.1-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.0, longitude: 135.0),
              Location(latitude: 35.05, longitude: 135.05),
              Location(latitude: 35.1, longitude: 135.1),
            ],
            distanceMeters: 3200,
            durationSeconds: 900,
            instructions: const ['直進します', '左折します', '到着です'],
          ),
          '35.1,135.1->35.2,135.2-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.1, longitude: 135.1),
              Location(latitude: 35.15, longitude: 135.15),
              Location(latitude: 35.2, longitude: 135.2),
            ],
            distanceMeters: 2100,
            durationSeconds: 480,
            instructions: const ['右折します', '直進して目的地が右側です'],
          ),
        },
      );

      await pumpRouteInfoDialog(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      final summaryFinder = find.byKey(const Key('route_segment_summary_0'));
      expect(summaryFinder, findsOneWidget);

      // サマリーテキストの存在確認（実際のフォーマットに依存しない）
      final summaryRow = tester.widget<Row>(summaryFinder);
      final expandedWidget = summaryRow.children.whereType<Expanded>().first;
      final textWidget = expandedWidget.child as Text;
      expect(textWidget.data, contains('距離:'));
      expect(textWidget.data, contains('km'));
      expect(textWidget.data, contains('所要時間:'));
      expect(textWidget.data, contains('分'));

      expect(find.text('直進します'), findsNothing);

      // トグルボタンを画面に表示させるためスクロール
      final toggleFinder = find.byKey(const Key('route_segment_toggle_0'));
      await tester.dragUntilVisible(
        toggleFinder,
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('直進します'), findsOneWidget);
      expect(find.text('左折します'), findsOneWidget);
      expect(find.text('到着です'), findsOneWidget);

      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('直進します'), findsNothing);
    });

    testWidgets('中間のピンを選択した場合は前後の経路ハイライト色が異なること', (tester) async {
      final fakeService = FakeRouteInfoService(
        responses: {
          '35.0,135.0->35.1,135.1-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.0, longitude: 135.0),
              Location(latitude: 35.05, longitude: 135.05),
              Location(latitude: 35.1, longitude: 135.1),
            ],
            distanceMeters: 3200,
            durationSeconds: 900,
            instructions: const [],
          ),
          '35.1,135.1->35.2,135.2-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.1, longitude: 135.1),
              Location(latitude: 35.15, longitude: 135.15),
              Location(latitude: 35.2, longitude: 135.2),
            ],
            distanceMeters: 2100,
            durationSeconds: 480,
            instructions: const [],
          ),
        },
      );

      await pumpRouteInfoDialog(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(RouteInfoDialog)) as RouteInfoDialogState;

      state.selectPinForTest(1);
      await tester.pumpAndSettle();

      expect(state.selectedPinIndex, 1);

      final highlightColors = state.segmentHighlightColors;
      expect(highlightColors['pin-1->pin-2'], Colors.blueAccent);
      expect(highlightColors['pin-2->pin-3'], Colors.greenAccent);
    });

    testWidgets('経路詳細は移動手段プルダウンの下に表示されること', (tester) async {
      final fakeService = FakeRouteInfoService(
        responses: {
          '35.0,135.0->35.1,135.1-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.0, longitude: 135.0),
              Location(latitude: 35.1, longitude: 135.1),
            ],
            distanceMeters: 1500,
            durationSeconds: 420,
            instructions: const ['直進します'],
          ),
        },
      );

      await pumpRouteInfoDialog(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      // 経路詳細を画面に表示させるためスクロール
      await tester.dragUntilVisible(
        find.byKey(const Key('route_segment_summary_0')),
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final dropdownRect = tester.getRect(
        find.byKey(const Key('route_segment_mode_0')),
      );
      final summaryRect = tester.getRect(
        find.byKey(const Key('route_segment_summary_0')),
      );

      // プルダウンよりサマリーが下にあることを確認
      expect(summaryRect.top, greaterThanOrEqualTo(dropdownRect.bottom));
    });

    testWidgets('経路詳細を展開すると経路案内が表示されること', (tester) async {
      final fakeService = FakeRouteInfoService(
        responses: {
          '35.0,135.0->35.1,135.1-TravelMode.drive': RouteSegmentDetail(
            polyline: const [
              Location(latitude: 35.0, longitude: 135.0),
              Location(latitude: 35.05, longitude: 135.05),
              Location(latitude: 35.1, longitude: 135.1),
            ],
            distanceMeters: 4200,
            durationSeconds: 1020,
            instructions: const ['南東に進みます', '交差点で左折します', '目的地は左側です'],
          ),
        },
      );

      await pumpRouteInfoDialog(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      expect(find.text('南東に進みます'), findsNothing);

      // トグルボタンを画面に表示させるためスクロール
      final toggleFinder = find.byKey(const Key('route_segment_toggle_0'));
      await tester.dragUntilVisible(
        toggleFinder,
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // 折りたたまれた状態の高さを取得
      final containerFinder = find.byKey(
        const Key('route_segment_container_0'),
      );
      final collapsedHeight = tester.getSize(containerFinder).height;

      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('南東に進みます'), findsOneWidget);
      expect(find.text('交差点で左折します'), findsOneWidget);
      expect(find.text('目的地は左側です'), findsOneWidget);

      // 展開後の高さを取得し、増加していることを確認
      final expandedHeight = tester.getSize(containerFinder).height;
      expect(expandedHeight, greaterThan(collapsedHeight));
    });

    testWidgets('マップを非表示にするとリスト領域が拡張されること', (tester) async {
      await pumpRouteInfoDialog(tester);

      final listAreaFinder = find.byKey(const Key('route_info_list_area'));
      final toggleFinder = find.byKey(const Key('route_info_map_toggle'));

      expect(listAreaFinder, findsOneWidget);
      expect(toggleFinder, findsOneWidget);

      final visibleSize = tester.getSize(listAreaFinder);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('route_info_map')), findsNothing);

      final hiddenSize = tester.getSize(listAreaFinder);
      expect(hiddenSize.height, greaterThan(visibleSize.height));

      // マップを再表示できることも確認
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('route_info_map')), findsOneWidget);
    });
  });
}
