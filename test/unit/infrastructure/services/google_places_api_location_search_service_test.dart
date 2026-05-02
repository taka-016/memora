import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';

void main() {
  group('GooglePlacesApiLocationSearchService', () {
    late LocationSearchService service;
    late http.BaseRequest capturedRequest;

    setUp(() {
      service = GooglePlacesApiLocationSearchService(
        apiKey: 'dummy',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          expect(request.method, 'POST');
          expect(request.url.host, 'places.googleapis.com');
          expect(request.url.path, '/v1/places:searchText');
          expect(request.url.queryParameters['key'], 'dummy');
          expect(
            request.url.queryParameters['fields'],
            'places.displayName,places.formattedAddress,places.location',
          );

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['textQuery'], '東京タワー');
          expect(body['languageCode'], 'ja');

          return http.Response(
            jsonEncode({
              'places': [
                {
                  'displayName': {'text': '東京タワー'},
                  'formattedAddress': '東京都港区芝公園４丁目２−８',
                  'location': {'latitude': 35.6586, 'longitude': 139.7454},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    });

    test('Text Searchで検索キーワードの候補が取得できる', () async {
      final results = await service.searchByKeyword('東京タワー');

      expect(results, isA<List<LocationCandidateDto>>());
      expect(results.length, 1);
      expect(results[0].name, '東京タワー');
      expect(results[0].address, '東京都港区芝公園４丁目２−８');
      expect(results[0].coordinate.latitude, 35.6586);
      expect(results[0].coordinate.longitude, 139.7454);
      expect(capturedRequest, isA<http.Request>());
    });
  });
}
