import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';

void main() {
  const origin = Location(latitude: 35.0, longitude: 135.0);
  const destination = Location(latitude: 35.1, longitude: 135.2);

  GoogleRoutesApiRouteInfoService buildService(MockClient client) {
    return GoogleRoutesApiRouteInfoService(apiKey: 'dummy', httpClient: client);
  }

  group('GoogleRoutesApiRouteInfoService.fetchRoute', () {
    test('TravelMode.otherではHTTPアクセスせず直線ルートを返す', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('"unused"', 200);
      });

      final service = buildService(client);

      final detail = await service.fetchRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.other,
      );

      expect(called, isFalse);
      expect(detail.polyline, [origin, destination]);
      expect(detail.distanceMeters, 0);
      expect(detail.durationSeconds, 0);
      expect(detail.instructions, isEmpty);
    });

    test('HTTPステータスが200以外なら例外を投げる', () async {
      final client = MockClient((request) async => http.Response('error', 500));

      final service = buildService(client);

      expect(
        () => service.fetchRoute(
          origin: origin,
          destination: destination,
          travelMode: TravelMode.walk,
        ),
        throwsException,
      );
    });

    test('routesが空ならRouteSegmentDetail.emptyを返しDrive用のBodyを送信する', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'routes': <dynamic>[]})),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = buildService(client);
      final result = await service.fetchRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.drive,
      );

      expect(result, const RouteSegmentDetail.empty());

      final decodedBody =
          jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(decodedBody['travelMode'], 'DRIVE');
      expect(decodedBody['routingPreference'], 'TRAFFIC_AWARE');
      expect(decodedBody['languageCode'], 'ja-JP');
    });

    test('レスポンスから距離・時間・指示・ポリラインを構築する', () async {
      const encodedPolyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final responseBody = {
        'routes': [
          {
            'polyline': {'encodedPolyline': encodedPolyline},
            'legs': [
              {
                'distanceMeters': 1234.5,
                'duration': '12.6s',
                'steps': [
                  {
                    'navigationInstruction': {
                      'instructions': '<div>北に進む</div>',
                    },
                  },
                  {
                    'navigationInstruction': {'instructions': '<b>左折</b>'},
                  },
                ],
              },
            ],
          },
        ],
      };

      final client = MockClient(
        (request) async => http.Response.bytes(
          utf8.encode(jsonEncode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final service = buildService(client);

      final detail = await service.fetchRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.walk,
      );

      expect(detail.distanceMeters, 1235);
      expect(detail.durationSeconds, 13);
      expect(detail.instructions, ['北に進む', '左折']);
      expect(detail.polyline.length, 3);
      expect(detail.polyline[0].latitude, closeTo(38.5, 1e-3));
      expect(detail.polyline[0].longitude, closeTo(-120.2, 1e-3));
      expect(detail.polyline[2].latitude, closeTo(43.252, 1e-3));
      expect(detail.polyline[2].longitude, closeTo(-126.453, 1e-3));
    });

    test('ルートポリラインが無い場合でもlegのポリラインを利用する', () async {
      const legPolyline = 'gfo}EtohhUxD@bAxJmGF';
      final responseBody = {
        'routes': [
          {
            'legs': [
              {
                'distanceMeters': 10,
                'duration': '5s',
                'steps': <dynamic>[],
                'polyline': {'encodedPolyline': legPolyline},
              },
            ],
          },
        ],
      };

      final client = MockClient(
        (request) async => http.Response.bytes(
          utf8.encode(jsonEncode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final service = buildService(client);

      final detail = await service.fetchRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.walk,
      );

      expect(detail.polyline, isNotEmpty);
      expect(detail.polyline.first.latitude, closeTo(36.45556, 1e-5));
      expect(detail.polyline.first.longitude, closeTo(-116.86667, 1e-5));
    });
  });
}
