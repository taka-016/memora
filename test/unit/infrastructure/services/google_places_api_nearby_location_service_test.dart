import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/infrastructure/services/google_places_api_nearby_location_service.dart';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'google_places_api_nearby_location_service_test.mocks.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
void main() {
  group('GooglePlacesApiNearbyLocationService', () {
    late NearbyLocationService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = GooglePlacesApiNearbyLocationService(
        apiKey: 'dummy',
        httpClient: mockClient,
      );
    });

    test('serviceが正しく初期化される', () {
      expect(service, isNotNull);
      expect(service, isA<GooglePlacesApiNearbyLocationService>());
    });

    test('位置情報から場所名を取得できる', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"places":[{"displayName":{"text":"東京タワー"}}]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      final result = await service.getLocationName(location);
      expect(result, '東京タワー');
    });

    test('API呼び出しが失敗した場合はnullを返す', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      final result = await service.getLocationName(location);
      expect(result, isNull);
    });

    test('場所が見つからない場合はnullを返す', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"places":[]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      final result = await service.getLocationName(location);
      expect(result, isNull);
    });

    test('指定した半径でnearby検索できる', () async {
      service = GooglePlacesApiNearbyLocationService(
        apiKey: 'dummy',
        httpClient: mockClient,
        searchRadiusInMeters: 50,
      );

      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"places":[{"displayName":{"text":"東京タワー"}}]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      const location = Coordinate(latitude: 35.6586, longitude: 139.7454);

      await service.getLocationName(location);

      final captured = verify(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ),
      ).captured;
      final requestBody =
          jsonDecode(captured.single as String) as Map<String, dynamic>;

      expect(
        ((requestBody['locationRestriction'] as Map<String, dynamic>)['circle']
            as Map<String, dynamic>)['radius'],
        50,
      );
    });
  });
}
