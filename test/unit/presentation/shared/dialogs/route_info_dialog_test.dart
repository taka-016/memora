import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/travel_mode.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog.dart';

class FakeRouteInfoService implements RouteInfoService {
  final List<_RouteRequest> _requests = [];
  final Map<String, List<Location>> responses;

  FakeRouteInfoService({required this.responses});

  int get callCount => _requests.length;

  @override
  Future<List<Location>> fetchRoute({
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
    return responses[key] ?? [];
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
          '35.0,135.0->35.1,135.1-TravelMode.drive': [
            const Location(latitude: 35.0, longitude: 135.0),
            const Location(latitude: 35.05, longitude: 135.05),
            const Location(latitude: 35.1, longitude: 135.1),
          ],
          '35.1,135.1->35.2,135.2-TravelMode.drive': [
            const Location(latitude: 35.1, longitude: 135.1),
            const Location(latitude: 35.15, longitude: 135.15),
            const Location(latitude: 35.2, longitude: 135.2),
          ],
        },
      );

      await pumpRouteInfoDialog(tester, service: fakeService);

      await tester.tap(find.text('経路検索'));
      await tester.pumpAndSettle();

      expect(fakeService.callCount, 2);

      final state =
          tester.state(find.byType(RouteInfoDialog)) as RouteInfoDialogState;
      expect(state.segmentResults.length, 2);
    });

    testWidgets('マップ表示切り替えボタンはマップ右上に表示されること', (tester) async {
      await pumpRouteInfoDialog(tester);

      final toggleFinder = find.byKey(const Key('route_info_map_toggle'));
      final mapAreaFinder = find.byKey(const Key('route_info_map_area'));

      expect(toggleFinder, findsOneWidget);
      expect(mapAreaFinder, findsOneWidget);

      final toggleRect = tester.getRect(toggleFinder);
      final mapRect = tester.getRect(mapAreaFinder);

      expect(mapRect.contains(toggleRect.topLeft), isTrue);
      expect(mapRect.contains(toggleRect.topRight), isTrue);
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
