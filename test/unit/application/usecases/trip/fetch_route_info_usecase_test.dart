import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/usecases/trip/fetch_route_info_usecase.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'fetch_route_info_usecase_test.mocks.dart';

@GenerateMocks([RouteInfoService])
void main() {
  late MockRouteInfoService mockRouteInfoService;
  late FetchRouteInfoUsecase usecase;

  final origin = PinDto(
    pinId: 'pin-1',
    latitude: 35.0,
    longitude: 135.0,
    locationName: '出発地',
  );
  final destination = PinDto(
    pinId: 'pin-2',
    latitude: 35.1,
    longitude: 135.1,
    locationName: '到着地',
  );

  setUp(() {
    mockRouteInfoService = MockRouteInfoService();
    usecase = FetchRouteInfoUsecase(mockRouteInfoService);
  });

  group('FetchRouteInfoUsecase', () {
    test('ピンが1件以下の場合は空の結果を返し、サービス呼び出しをしない', () async {
      final result = await usecase.execute(
        pins: [origin],
        segmentModes: const {},
        existingDetails: const {},
      );

      expect(result, isEmpty);
      verifyNever(
        mockRouteInfoService.fetchRoute(
          origin: anyNamed('origin'),
          destination: anyNamed('destination'),
          travelMode: anyNamed('travelMode'),
        ),
      );
    });

    test('移動手段が未指定の場合は自動車で経路取得する', () async {
      final fetchedDetail = RouteSegmentDetail(
        polyline: const [Location(latitude: 0, longitude: 0)],
        distanceMeters: 1200,
        durationSeconds: 600,
        instructions: const ['直進'],
      );
      when(
        mockRouteInfoService.fetchRoute(
          origin: anyNamed('origin'),
          destination: anyNamed('destination'),
          travelMode: anyNamed('travelMode'),
        ),
      ).thenAnswer((_) async => fetchedDetail);

      final result = await usecase.execute(
        pins: [origin, destination],
        segmentModes: const {},
        existingDetails: const {},
      );

      expect(result.values.single, equals(fetchedDetail));
      final capturedModes = verify(
        mockRouteInfoService.fetchRoute(
          origin: anyNamed('origin'),
          destination: anyNamed('destination'),
          travelMode: captureAnyNamed('travelMode'),
        ),
      ).captured;
      expect(capturedModes.single, equals(TravelMode.drive));
    });

    test('その他の経路で手動入力がある場合、取得結果のPolylineのみ反映する', () async {
      final key = '${origin.pinId}->${destination.pinId}';
      final existingDetail = RouteSegmentDetail(
        polyline: const [],
        distanceMeters: 0,
        durationSeconds: 300,
        instructions: const ['手動メモ'],
      );
      final fetchedDetail = RouteSegmentDetail(
        polyline: const [Location(latitude: 1, longitude: 1)],
        distanceMeters: 0,
        durationSeconds: 0,
        instructions: const [],
      );
      when(
        mockRouteInfoService.fetchRoute(
          origin: anyNamed('origin'),
          destination: anyNamed('destination'),
          travelMode: anyNamed('travelMode'),
        ),
      ).thenAnswer((_) async => fetchedDetail);

      final result = await usecase.execute(
        pins: [origin, destination],
        segmentModes: {key: TravelMode.other},
        existingDetails: {key: existingDetail},
      );

      final detail = result[key];
      expect(detail, isNotNull);
      expect(detail!.polyline, equals(fetchedDetail.polyline));
      expect(detail.durationSeconds, equals(existingDetail.durationSeconds));
      expect(detail.instructions, equals(existingDetail.instructions));
    });

    test('サービスで例外が発生した場合、そのまま伝播する', () async {
      when(
        mockRouteInfoService.fetchRoute(
          origin: anyNamed('origin'),
          destination: anyNamed('destination'),
          travelMode: anyNamed('travelMode'),
        ),
      ).thenThrow(TestException('経路取得失敗'));

      expect(
        () => usecase.execute(
          pins: [origin, destination],
          segmentModes: const {},
          existingDetails: const {},
        ),
        throwsA(isA<TestException>()),
      );
    });
  });
}
