import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';

void main() {
  group('LocationUsecases', () {
    late _FakeLocationQueryService queryService;

    setUp(() {
      queryService = _FakeLocationQueryService();
    });

    test('グループIDで場所一覧を取得する', () async {
      const expected = [
        LocationDto(
          id: 'location-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.0,
          longitude: 139.0,
        ),
      ];
      queryService.locationsByGroupId['group-1'] = expected;

      final result = await GetLocationsByGroupIdUsecase(
        queryService,
      ).execute('group-1');

      expect(result, expected);
      expect(queryService.requestedGroupIds, ['group-1']);
    });
  });
}

class _FakeLocationQueryService implements LocationQueryService {
  final locationsByGroupId = <String, List<LocationDto>>{};
  final requestedGroupIds = <String>[];

  @override
  Future<List<LocationDto>> getLocationsByGroupId(String groupId) async {
    requestedGroupIds.add(groupId);
    return locationsByGroupId[groupId] ?? const [];
  }
}
