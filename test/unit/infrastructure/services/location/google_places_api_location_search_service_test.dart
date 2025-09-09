import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/location_candidate.dart';
import 'package:memora/infrastructure/services/location/google_places_api_location_search_service.dart';
import 'package:memora/domain/services/location/location_search_service.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'google_places_api_location_search_service_test.mocks.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
void main() {
  group('GooglePlacesApiLocationSearchService', () {
    late LocationSearchService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = GooglePlacesApiLocationSearchService(
        apiKey: 'dummy',
        httpClient: mockClient,
      );
    });

    test('検索キーワードで候補が取得できる', () async {
      // モックのレスポンスを設定
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response.bytes(
          utf8.encode(
            '{"results":[{"name":"東京タワー","formatted_address":"東京都港区芝公園４丁目２−８","geometry":{"location":{"lat":35.6586,"lng":139.7454}}}]}',
          ),
          200,
        ),
      );

      final results = await service.searchByKeyword('東京タワー');
      expect(results, isA<List<LocationCandidate>>());
      expect(results.length, 1);
      expect(results[0].name, '東京タワー');
      expect(results[0].address, '東京都港区芝公園４丁目２−８');
      expect(results[0].location.latitude, 35.6586);
      expect(results[0].location.longitude, 139.7454);
    });
  });
}
