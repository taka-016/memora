import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_leg.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog_controller.dart';

class _RecordingRouteInformationService implements RouteInformationService {
  final List<List<RouteLocation>> requestedLocations = [];
  final List<RouteTravelMode> requestedModes = [];
  final List<DateTime?> requestedDepartureTimes = [];
  int callCount = 0;
  List<RouteCandidate> response = const [];

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
    return response;
  }
}

List<PinDto> _createPins() {
  return [
    PinDto(
      pinId: 'pin1',
      latitude: 35.0,
      longitude: 139.0,
      locationName: 'A地点',
      visitStartDate: DateTime(2024, 1, 1, 9),
    ),
    PinDto(
      pinId: 'pin2',
      latitude: 35.1,
      longitude: 139.1,
      locationName: 'B地点',
    ),
    PinDto(
      pinId: 'pin3',
      latitude: 35.2,
      longitude: 139.2,
      locationName: 'C地点',
    ),
  ];
}

void main() {
  group('RouteInfoDialogController', () {
    late _RecordingRouteInformationService service;
    late DateTime now;

    setUp(() {
      service = _RecordingRouteInformationService();
      service.response = const [
        RouteCandidate(
          description: 'テスト候補',
          localizedDistanceText: '5 km',
          localizedDurationText: '12分',
          legs: [
            RouteLeg(
              localizedDistanceText: '5 km',
              localizedDurationText: '12分',
              primaryInstruction: '直進',
            ),
          ],
          warnings: [],
        ),
      ];
      now = DateTime(2024, 1, 10, 12);
    });

    test('初期状態でピン順と区間情報が構築される', () {
      final controller = RouteInfoDialogController(
        pins: _createPins(),
        routeInformationService: service,
        nowProvider: () => now,
      );

      expect(controller.pins.map((pin) => pin.pinId), ['pin1', 'pin2', 'pin3']);
      expect(controller.segments.length, 2);
      expect(
        controller.segments.map((segment) => segment.travelMode),
        everyElement(equals(RouteTravelMode.drive)),
      );
    });

    test('区間の移動手段を更新できる', () {
      final controller = RouteInfoDialogController(
        pins: _createPins(),
        routeInformationService: service,
        nowProvider: () => now,
      );

      controller.updateTravelMode(0, RouteTravelMode.walk);
      controller.updateTravelMode(1, RouteTravelMode.transit);

      expect(controller.segments[0].travelMode, RouteTravelMode.walk);
      expect(controller.segments[1].travelMode, RouteTravelMode.transit);
    });

    test('ピンを並べ替えると区間情報が更新される', () {
      final controller = RouteInfoDialogController(
        pins: _createPins(),
        routeInformationService: service,
        nowProvider: () => now,
      );

      controller.reorderPins(oldIndex: 0, newIndex: 2);

      expect(controller.pins.map((pin) => pin.pinId), ['pin2', 'pin1', 'pin3']);
      expect(controller.segments[0].from.pinId, 'pin2');
      expect(controller.segments[0].to.pinId, 'pin1');
      expect(controller.segments[1].from.pinId, 'pin1');
      expect(controller.segments[1].to.pinId, 'pin3');
    });

    test('経路検索で区間ごとにRoutes APIを呼び出し結果を保存する', () async {
      final controller = RouteInfoDialogController(
        pins: _createPins(),
        routeInformationService: service,
        nowProvider: () => now,
      );

      controller.updateTravelMode(1, RouteTravelMode.walk);
      await controller.searchRoutes();

      expect(service.callCount, 2);
      expect(service.requestedModes, [
        RouteTravelMode.drive,
        RouteTravelMode.walk,
      ]);
      expect(
        service.requestedLocations.map((locations) => locations.length),
        everyElement(equals(2)),
      );
      expect(controller.segments[0].candidate, isNotNull);
      expect(controller.segments[1].candidate, isNotNull);
    });

    test('visitStartDateが未設定の場合は現在時刻を出発時間として利用する', () async {
      final pins = _createPins();
      final controller = RouteInfoDialogController(
        pins: pins,
        routeInformationService: service,
        nowProvider: () => now,
      );

      await controller.searchRoutes();

      expect(service.requestedDepartureTimes.length, 2);
      expect(service.requestedDepartureTimes[0], pins[0].visitStartDate);
      expect(service.requestedDepartureTimes[1], now);
    });
  });
}
