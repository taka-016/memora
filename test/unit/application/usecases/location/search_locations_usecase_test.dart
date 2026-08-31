import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'search_locations_usecase_test.mocks.dart';

@GenerateMocks([LocationSearchService])
void main() {
  group('SearchLocationsUsecase', () {
    late MockLocationSearchService mockLocationSearchService;
    late SearchLocationsUsecase usecase;

    setUp(() {
      mockLocationSearchService = MockLocationSearchService();
      usecase = SearchLocationsUsecase(mockLocationSearchService);
    });

    test('キーワードを渡して検索結果を返す', () async {
      const keyword = '東京駅';
      final expected = [
        const LocationCandidateDto(
          name: '東京駅',
          address: '東京都千代田区丸の内1-9-1',
          coordinate: Coordinate(latitude: 35.681236, longitude: 139.767125),
        ),
      ];
      when(mockLocationSearchService.searchByKeyword(keyword))
          .thenAnswer((_) async => expected);

      final actual = await usecase.execute(keyword);

      expect(actual, expected);
      verify(mockLocationSearchService.searchByKeyword(keyword)).called(1);
    });
  });
}
