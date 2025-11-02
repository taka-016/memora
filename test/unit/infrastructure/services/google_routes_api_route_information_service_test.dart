import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_information_service.dart';

void main() {
  group('GoogleRoutesApiRouteInformationService', () {
    late RouteInformationService service;
    late List<http.Request> capturedRequests;

    setUp(() {
      capturedRequests = [];
    });

    test('travelModeが指定された場合にリクエストボディへ含めること', () async {
      final client = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response(
          jsonEncode({'routes': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      service = GoogleRoutesApiRouteInformationService(
        apiKey: 'dummy-key',
        httpClient: client,
      );

      await service.fetchRoutes(
        locations: const [
          RouteLocation(id: 'a', latitude: 35.0, longitude: 139.0),
          RouteLocation(id: 'b', latitude: 36.0, longitude: 140.0),
        ],
        travelMode: RouteTravelMode.drive,
      );

      expect(capturedRequests.length, 1);
      final body =
          jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
      expect(body['travelMode'], equals('DRIVE'));
    });

    test('レスポンスをRouteCandidateへ変換すること', () async {
      final responseJson = {
        'routes': [
          {
            'description': '主要道路経由',
            'localizedValues': {
              'distance': {'text': '12 km'},
              'duration': {'text': '25分'},
            },
            'warnings': ['徒歩モードはエリアによって制限される場合があります。'],
            'legs': [
              {
                'localizedValues': {
                  'distance': {'text': '5 km'},
                  'duration': {'text': '10分'},
                },
                'steps': [
                  {
                    'navigationInstruction': {'instructions': '国道1号線を北に進む'},
                  },
                ],
              },
              {
                'localizedValues': {
                  'distance': {'text': '7 km'},
                  'duration': {'text': '15分'},
                },
                'steps': [
                  {
                    'navigationInstruction': {'instructions': '目的地は右側です'},
                  },
                ],
              },
            ],
          },
          {
            'description': '高速道路経由',
            'localizedValues': {
              'distance': {'text': '11 km'},
              'duration': {'text': '22分'},
            },
            'warnings': [],
            'legs': [
              {
                'localizedValues': {
                  'distance': {'text': '6 km'},
                  'duration': {'text': '12分'},
                },
                'steps': [
                  {
                    'navigationInstruction': {'instructions': '高速道路に入る'},
                  },
                ],
              },
              {
                'localizedValues': {
                  'distance': {'text': '5 km'},
                  'duration': {'text': '10分'},
                },
                'steps': [
                  {
                    'navigationInstruction': {'instructions': '出口で降りる'},
                  },
                ],
              },
            ],
          },
        ],
      };

      final client = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response(
          jsonEncode(responseJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      service = GoogleRoutesApiRouteInformationService(
        apiKey: 'dummy-key',
        httpClient: client,
      );

      final result = await service.fetchRoutes(
        locations: const [
          RouteLocation(id: 'a', latitude: 35.0, longitude: 139.0),
          RouteLocation(id: 'b', latitude: 36.0, longitude: 140.0),
          RouteLocation(id: 'c', latitude: 37.0, longitude: 141.0),
        ],
        travelMode: RouteTravelMode.drive,
      );

      expect(result.length, 2);
      expect(result.first.description, '主要道路経由');
      expect(result.first.localizedDistanceText, '12 km');
      expect(result.first.localizedDurationText, '25分');
      expect(result.first.legs.length, 2);
      expect(result.first.legs.first.localizedDistanceText, '5 km');
      expect(result.first.legs.first.localizedDurationText, '10分');
      expect(result.first.legs.first.primaryInstruction, '国道1号線を北に進む');
    });
  });
}
