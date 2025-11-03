import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_leg.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog_controller.dart';

class _RecordingRouteInformationService implements RouteInformationService {
  final List<List<RouteLocation>> requestedLocations = [];
  final List<RouteTravelMode> requestedModes = [];
  final List<DateTime?> requestedDepartureTimes = [];
  final List<List<RouteCandidate>> responseQueue = [];
  int callCount = 0;

  Completer<void>? waitCompleter;

  @override
  Future<List<RouteCandidate>> fetchRoutes({
    required List<RouteLocation> locations,
    required RouteTravelMode travelMode,
    DateTime? departureTime,
  }) async {
    requestedLocations.add(locations);
    requestedModes.add(travelMode);
    requestedDepartureTimes.add(departureTime);
    callCount++;
    await waitCompleter?.future;
    if (responseQueue.isEmpty) {
      return const [];
    }
    return responseQueue.removeAt(0);
  }
}

List<PinDto> _createPins() {
  return [
    PinDto(
      pinId: 'pin1',
      latitude: 35.0,
      longitude: 139.0,
      locationName: '那覇空港',
      visitStartDate: DateTime(2024, 1, 1, 8),
    ),
    PinDto(
      pinId: 'pin2',
      latitude: 26.2,
      longitude: 127.7,
      locationName: '首里城',
    ),
    PinDto(
      pinId: 'pin3',
      latitude: 26.5,
      longitude: 127.9,
      locationName: '美ら海水族館',
    ),
  ];
}

RouteCandidate _createCandidate({
  required String description,
  required String distance,
  required String duration,
}) {
  return RouteCandidate(
    description: description,
    localizedDistanceText: distance,
    localizedDurationText: duration,
    legs: const [
      RouteLeg(
        localizedDistanceText: '5 km',
        localizedDurationText: '10分',
        primaryInstruction: '直進してください',
      ),
    ],
    warnings: const [],
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required RouteInformationService service,
  required List<PinDto> pins,
  DateTime Function()? nowProvider,
  void Function(RouteInfoDialogController controller)? onControllerReady,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RouteInfoDialog(
        pins: pins,
        routeInformationService: service,
        isTestEnvironment: true,
        nowProvider: nowProvider,
        onControllerReady: onControllerReady,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouteInfoDialog', () {
    late _RecordingRouteInformationService service;
    late List<PinDto> pins;
    late DateTime now;

    setUp(() {
      service = _RecordingRouteInformationService();
      pins = _createPins();
      now = DateTime(2024, 1, 5, 9, 30);
      service.responseQueue
        ..clear()
        ..addAll([
          [
            _createCandidate(
              description: '候補A',
              distance: '12 km',
              duration: '25分',
            ),
          ],
          [
            _createCandidate(
              description: '候補B',
              distance: '30 km',
              duration: '45分',
            ),
          ],
        ]);
    });

    testWidgets('経路検索ボタンを押すと区間ごとにRoutes APIが呼び出される', (tester) async {
      RouteInfoDialogController? capturedController;
      await _pumpDialog(
        tester,
        service: service,
        pins: pins,
        nowProvider: () => now,
        onControllerReady: (controller) => capturedController = controller,
      );

      expect(service.callCount, 0);
      expect(capturedController, isNotNull);
      capturedController!.updateTravelMode(1, RouteTravelMode.walk);

      await tester.tap(find.byKey(const Key('route_search_button')));
      await tester.pumpAndSettle();

      expect(capturedController!.segments[0].candidate, isNotNull);
      expect(capturedController!.segments[1].candidate, isNotNull);

      expect(service.callCount, 2);
      expect(service.requestedModes, [
        RouteTravelMode.drive,
        RouteTravelMode.walk,
      ]);
      expect(service.requestedDepartureTimes[0], pins[0].visitStartDate);
      expect(service.requestedDepartureTimes[1], now);
      expect(
        find.textContaining('25分', findRichText: true, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('45分', findRichText: true, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('ピンをタップするとマップハイライトが更新される', (tester) async {
      RouteInfoDialogController? controller;
      await _pumpDialog(
        tester,
        service: service,
        pins: pins,
        nowProvider: () => now,
        onControllerReady: (c) => controller = c,
      );

      await tester.tap(find.byKey(const Key('route_search_button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('route_info_map_placeholder')),
          matching: find.textContaining('pin1 → pin2'),
        ),
        findsOneWidget,
      );

      controller!.selectPin('pin3');
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('route_info_map_placeholder')),
          matching: find.textContaining('pin2 → pin3'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('マップ表示は+/-アイコンで切り替えられる', (tester) async {
      await _pumpDialog(
        tester,
        service: service,
        pins: pins,
        nowProvider: () => now,
      );

      await tester.tap(find.byKey(const Key('route_search_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('route_info_map_placeholder')),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(find.byKey(const Key('route_info_map_placeholder')), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(
        find.byKey(const Key('route_info_map_placeholder')),
        findsOneWidget,
      );
    });

    testWidgets('ピンの並べ替えが検索結果に反映される', (tester) async {
      RouteInfoDialogController? controller;
      await _pumpDialog(
        tester,
        service: service,
        pins: pins,
        nowProvider: () => now,
        onControllerReady: (c) => controller = c,
      );

      controller!.reorderPins(oldIndex: 0, newIndex: controller!.pins.length);
      await tester.pump();

      service.responseQueue
        ..clear()
        ..addAll([
          [
            _createCandidate(
              description: '候補C',
              distance: '8 km',
              duration: '18分',
            ),
          ],
          [
            _createCandidate(
              description: '候補D',
              distance: '12 km',
              duration: '25分',
            ),
          ],
        ]);

      await tester.tap(find.byKey(const Key('route_search_button')));
      await tester.pumpAndSettle();

      expect(service.requestedLocations.length, 2);
      expect(service.requestedLocations[0].first.id, 'pin2');
      expect(service.requestedLocations[0].last.id, 'pin3');
      expect(service.requestedLocations[1].first.id, 'pin3');
      expect(service.requestedLocations[1].last.id, 'pin1');
    });
  });
}
