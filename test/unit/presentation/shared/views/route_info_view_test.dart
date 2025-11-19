import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/constants/color_constants.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/presentation/shared/views/route_info_view.dart';

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

    if (travelMode == TravelMode.other) {
      return RouteSegmentDetail(
        polyline: [
          Location(latitude: origin.latitude, longitude: origin.longitude),
          Location(
            latitude: destination.latitude,
            longitude: destination.longitude,
          ),
        ],
        distanceMeters: 0,
        durationSeconds: 0,
        instructions: const [],
      );
    }
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

  Future<void> pumpRouteInfoView(
    WidgetTester tester, {
    RouteInfoService? service,
    VoidCallback? onClose,
    List<PinDto>? overridePins,
  }) async {
    final targetPins = overridePins ?? pins;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteInfoView(
            pins: targetPins,
            routeInfoService: service,
            isTestEnvironment: true,
            onClose: onClose,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('RouteInfoView', () {
    testWidgets('ピンのリストはlocationNameのみ表示すること', (tester) async {
      await pumpRouteInfoView(tester);

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
      await pumpRouteInfoView(tester);

      final dropdowns = find.byKey(const Key('route_segment_mode_0'));
      expect(dropdowns, findsOneWidget);
      expect(
        find.descendant(of: dropdowns, matching: find.text('自動車')),
        findsOneWidget,
      );
    });

    testWidgets('移動手段プルダウンでその他を選択すると経路入力アイコンが表示されること', (tester) async {
      await pumpRouteInfoView(tester);

      await tester.tap(find.byKey(const Key('route_segment_mode_0')));
      await tester.pumpAndSettle();

      expect(find.text('その他'), findsWidgets);

      await tester.tap(find.text('その他').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('route_segment_other_route_icon_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('route_segment_other_input_0')),
        findsNothing,
      );
    });

    testWidgets('ピンをタップすると選択状態になりハイライトされること', (tester) async {
      await pumpRouteInfoView(tester);

      final pinTileFinder = find.byKey(const Key('route_info_pin_tile_pin-1'));
      await tester.tap(pinTileFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(RouteInfoView)) as RouteInfoViewState;
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

      await pumpRouteInfoView(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      expect(fakeService.callCount, 2);

      final state =
          tester.state(find.byType(RouteInfoView)) as RouteInfoViewState;
      expect(state.segmentDetails.length, 2);
    });

    testWidgets('その他の経路入力はボトムシートから保存され経路情報に反映されること', (tester) async {
      final fakeService = FakeRouteInfoService(responses: {});

      await pumpRouteInfoView(tester, service: fakeService);

      await tester.tap(find.byKey(const Key('route_segment_mode_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('その他').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('route_segment_other_route_icon_0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('other_route_info_bottom_sheet')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('other_route_duration_field')),
        '15',
      );
      await tester.enterText(
        find.byKey(const Key('other_route_instructions_field')),
        '自転車で移動\n徒歩で移動',
      );

      await tester.tap(find.byKey(const Key('other_route_sheet_close_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      expect(fakeService.callCount, 2);

      final state =
          tester.state(find.byType(RouteInfoView)) as RouteInfoViewState;
      final segmentKey = 'pin-1->pin-2';
      final detail = state.segmentDetails[segmentKey];
      expect(detail, isNotNull);
      expect(detail!.polyline.length, 2);
      expect(
        detail.polyline.first,
        const Location(latitude: 35.0, longitude: 135.0),
      );
      expect(
        detail.polyline.last,
        const Location(latitude: 35.1, longitude: 135.1),
      );
      expect(detail.instructions, ['自転車で移動', '徒歩で移動']);
      expect(detail.durationSeconds, 900);
    });

    testWidgets('ボトムシートを閉じると入力したルートメモが即時に表示されること', (tester) async {
      await pumpRouteInfoView(tester);

      await tester.tap(find.byKey(const Key('route_segment_mode_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('その他').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('route_segment_other_route_icon_0')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('other_route_duration_field')),
        '20',
      );
      await tester.enterText(
        find.byKey(const Key('other_route_instructions_field')),
        'ケーブルカー\n徒歩',
      );

      await tester.tap(find.byKey(const Key('other_route_sheet_close_button')));
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const Key('route_memo_toggle_button_0'));
      await tester.dragUntilVisible(
        toggleFinder,
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('所要時間: 約20分'), findsOneWidget);
      expect(find.text('経路案内'), findsOneWidget);
      expect(find.text('ケーブルカー'), findsOneWidget);
      expect(find.text('徒歩'), findsOneWidget);
    });

    testWidgets('経路検索後にルートメモとして距離と時間および経路案内を表示できること', (tester) async {
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

      await pumpRouteInfoView(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      final summaryFinder = find.byKey(const Key('route_memo_toggle_label_0'));
      expect(summaryFinder, findsOneWidget);

      // サマリーテキストが指定のラベルで表示されること
      final summaryRow = tester.widget<Row>(summaryFinder);
      final expandedWidget = summaryRow.children.whereType<Expanded>().first;
      final textWidget = expandedWidget.child as Text;
      expect(textWidget.data, 'ルートメモ');

      expect(find.text('距離: 約3.2km'), findsNothing);
      expect(find.text('所要時間: 約15分'), findsNothing);
      expect(find.text('経路案内'), findsNothing);

      // トグルボタンを画面に表示させるためスクロール
      final toggleFinder = find.byKey(const Key('route_memo_toggle_button_0'));
      await tester.dragUntilVisible(
        toggleFinder,
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('距離: 約3.2km'), findsOneWidget);
      expect(find.text('所要時間: 約15分'), findsOneWidget);
      expect(find.text('経路案内'), findsOneWidget);
      expect(find.text('直進します'), findsOneWidget);
      expect(find.text('左折します'), findsOneWidget);
      expect(find.text('到着です'), findsOneWidget);

      await tester.tap(toggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('距離: 約3.2km'), findsNothing);
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

      await pumpRouteInfoView(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(RouteInfoView)) as RouteInfoViewState;

      state.selectPinForTest(1);
      await tester.pumpAndSettle();

      expect(state.selectedPinIndex, 1);

      final highlightColors = state.segmentHighlightColors;
      expect(
        highlightColors['pin-1->pin-2'],
        ColorConstants.getSequentialColor(0),
      );
      expect(
        highlightColors['pin-2->pin-3'],
        ColorConstants.getSequentialColor(1),
      );
    });

    testWidgets('Polylineカラーは10色でローテーションすること', (tester) async {
      final extendedPins = List<PinDto>.generate(
        12,
        (index) => PinDto(
          pinId: 'pin-${index + 1}',
          latitude: 35.0 + index * 0.01,
          longitude: 135.0 + index * 0.01,
          locationName: 'スポット${index + 1}',
        ),
      );

      final responses = <String, RouteSegmentDetail>{};
      for (var i = 0; i < extendedPins.length - 1; i++) {
        final origin = extendedPins[i];
        final destination = extendedPins[i + 1];
        responses['${origin.latitude},${origin.longitude}->${destination.latitude},${destination.longitude}-${TravelMode.drive}'] =
            RouteSegmentDetail(
              polyline: [
                Location(
                  latitude: origin.latitude,
                  longitude: origin.longitude,
                ),
                Location(
                  latitude: destination.latitude,
                  longitude: destination.longitude,
                ),
              ],
              distanceMeters: 1000,
              durationSeconds: 600,
              instructions: const [],
            );
      }

      final fakeService = FakeRouteInfoService(responses: responses);

      await pumpRouteInfoView(
        tester,
        service: fakeService,
        overridePins: extendedPins,
      );

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      final state =
          tester.state(find.byType(RouteInfoView)) as RouteInfoViewState;

      final highlightColors = state.segmentHighlightColors;
      for (var i = 0; i < extendedPins.length - 1; i++) {
        final key = 'pin-${i + 1}->pin-${i + 2}';
        final paletteColor = ColorConstants.getSequentialColor(i);
        expect(highlightColors[key], paletteColor);
      }
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

      await pumpRouteInfoView(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      // 経路詳細を画面に表示させるためスクロール
      await tester.dragUntilVisible(
        find.byKey(const Key('route_memo_toggle_label_0')),
        find.byKey(const Key('route_info_reorderable_list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final dropdownRect = tester.getRect(
        find.byKey(const Key('route_segment_mode_0')),
      );
      final summaryRect = tester.getRect(
        find.byKey(const Key('route_memo_toggle_label_0')),
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

      await pumpRouteInfoView(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      expect(find.text('南東に進みます'), findsNothing);

      // トグルボタンを画面に表示させるためスクロール
      final toggleFinder = find.byKey(const Key('route_memo_toggle_button_0'));
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
      await pumpRouteInfoView(tester);

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
