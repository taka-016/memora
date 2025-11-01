import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_leg.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog.dart';

class FakeRouteInformationService implements RouteInformationService {
  RouteTravelMode? lastRequestedMode;
  List<RouteLocation>? lastRequestedLocations;
  int callCount = 0;
  List<RouteCandidate> response = const [];

  @override
  Future<List<RouteCandidate>> fetchRoutes({
    required List<RouteLocation> locations,
    required RouteTravelMode travelMode,
  }) async {
    lastRequestedMode = travelMode;
    lastRequestedLocations = locations;
    callCount++;
    return response;
  }
}

void main() {
  group('RouteInfoDialog', () {
    late FakeRouteInformationService fakeService;
    late List<PinDto> pins;

    setUp(() {
      fakeService = FakeRouteInformationService();
      pins = [
        PinDto(
          pinId: 'pin2',
          latitude: 35.3,
          longitude: 139.6,
          locationName: 'B地点',
          visitStartDate: DateTime(2024, 1, 2),
        ),
        PinDto(
          pinId: 'pin1',
          latitude: 35.2,
          longitude: 139.5,
          locationName: 'A地点',
          visitStartDate: DateTime(2024, 1, 1),
        ),
        PinDto(
          pinId: 'pin3',
          latitude: 35.4,
          longitude: 139.7,
          locationName: 'C地点',
          visitStartDate: DateTime(2024, 1, 3),
        ),
      ];

      fakeService.response = [
        RouteCandidate(
          description: '主要道路経由',
          localizedDistanceText: '11 km',
          localizedDurationText: '22分',
          legs: const [
            RouteLeg(
              localizedDistanceText: '5 km',
              localizedDurationText: '10分',
              primaryInstruction: '北に進む',
            ),
            RouteLeg(
              localizedDistanceText: '6 km',
              localizedDurationText: '12分',
              primaryInstruction: '目的地は右側',
            ),
          ],
          warnings: const [],
        ),
        RouteCandidate(
          description: '高速道路優先',
          localizedDistanceText: '10 km',
          localizedDurationText: '20分',
          legs: const [
            RouteLeg(
              localizedDistanceText: '4 km',
              localizedDurationText: '8分',
              primaryInstruction: '入口から高速道路へ',
            ),
            RouteLeg(
              localizedDistanceText: '6 km',
              localizedDurationText: '12分',
              primaryInstruction: '出口で降りる',
            ),
          ],
          warnings: const [],
        ),
      ];
    });

    testWidgets('初期表示で未選択の移動手段を使用してデータ取得する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteInfoDialog(
            pins: pins,
            routeInformationService: fakeService,
          ),
        ),
      );

      await tester.pump();

      expect(fakeService.callCount, 1);
      expect(fakeService.lastRequestedMode, RouteTravelMode.unspecified);
      expect(fakeService.lastRequestedLocations, isNotNull);
      expect(fakeService.lastRequestedLocations!.first.id, 'pin1');
      expect(fakeService.lastRequestedLocations!.last.id, 'pin3');
    });

    testWidgets('移動手段を切り替えると再取得し警告を表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteInfoDialog(
            pins: pins,
            routeInformationService: fakeService,
          ),
        ),
      );

      await tester.pump();
      expect(fakeService.callCount, 1);

      await tester.tap(find.text('徒歩'));
      await tester.pump();

      expect(fakeService.callCount, 2);
      expect(fakeService.lastRequestedMode, RouteTravelMode.walk);
      expect(
        find.text(
          '徒歩・自転車・バイクモードはすべての歩道や交通規制を反映していない可能性があります。必ず現地の状況を確認してください。',
        ),
        findsOneWidget,
      );
    });

    testWidgets('複数候補がある場合にタブで切り替えられる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteInfoDialog(
            pins: pins,
            routeInformationService: fakeService,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('候補1'), findsOneWidget);
      expect(find.text('候補2'), findsOneWidget);

      // デフォルトは候補1が表示される
      expect(find.text('主要道路経由'), findsOneWidget);

      await tester.tap(find.text('候補2'));
      await tester.pumpAndSettle();

      expect(find.text('高速道路優先'), findsOneWidget);
    });

    testWidgets('各区間の経路情報を矢印で表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteInfoDialog(
            pins: pins,
            routeInformationService: fakeService,
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.arrow_downward), findsNWidgets(2));
      expect(find.textContaining('5 km'), findsOneWidget);
      expect(find.textContaining('6 km'), findsOneWidget);
    });
  });
}
