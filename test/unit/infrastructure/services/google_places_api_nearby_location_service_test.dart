import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:memora/infrastructure/services/google_places_api_nearby_location_service.dart';

void main() {
  group('GooglePlacesApiNearbyLocationService', () {
    late NearbyLocationService service;
    late List<http.BaseRequest> requests;

    setUp(() {
      requests = [];
      service = GooglePlacesApiNearbyLocationService(
        apiKey: 'dummy',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'places': [
                {
                  'displayName': {'text': '東京タワー'},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    });

    test('serviceが正しく初期化される', () {
      expect(service, isNotNull);
      expect(service, isA<GooglePlacesApiNearbyLocationService>());
    });

    test('Nearby Searchで位置情報から場所名を取得できる', () async {
      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      final result = await service.getLocationName(location);

      expect(result, '東京タワー');
      expect(requests, hasLength(1));
      final request = requests.single as http.Request;
      expect(request.method, 'POST');
      expect(request.url.host, 'places.googleapis.com');
      expect(request.url.path, '/v1/places:searchNearby');
      expect(request.url.queryParameters['key'], 'dummy');
      expect(request.url.queryParameters['fields'], 'places.displayName');
      expect(request.headers.containsKey('X-Goog-Api-Key'), isFalse);

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['maxResultCount'], 1);
      expect(body['rankPreference'], 'POPULARITY');
      expect(body['languageCode'], 'ja');
      final locationRestriction =
          body['locationRestriction'] as Map<String, dynamic>;
      final circle = locationRestriction['circle'] as Map<String, dynamic>;
      expect(circle['radius'], 50.0);
      expect(circle['center'], {
        'latitude': location.latitude,
        'longitude': location.longitude,
      });
    });

    test('API呼び出しが失敗した場合はnullを返す', () async {
      service = GooglePlacesApiNearbyLocationService(
        apiKey: 'dummy',
        httpClient: MockClient((_) async => http.Response('Error', 500)),
      );

      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      final result = await service.getLocationName(location);
      expect(result, isNull);
    });

    test('場所が見つからない場合はnullを返す', () async {
      service = GooglePlacesApiNearbyLocationService(
        apiKey: 'dummy',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'places': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      final result = await service.getLocationName(location);
      expect(result, isNull);
    });
  });
}
