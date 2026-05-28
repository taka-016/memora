import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/application/usecases/trip/delete_location_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_trip_id_usecase.dart';
import 'package:memora/application/usecases/trip/save_location_usecase.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';

void main() {
  group('LocationUsecases', () {
    late _FakeLocationQueryService queryService;
    late _FakeLocationRepository repository;

    setUp(() {
      queryService = _FakeLocationQueryService();
      repository = _FakeLocationRepository();
    });

    test('旅行IDで場所一覧を取得する', () async {
      const expected = [
        LocationDto(
          id: 'location-1',
          tripId: 'trip-1',
          groupId: 'group-1',
          latitude: 35.0,
          longitude: 139.0,
        ),
      ];
      queryService.locationsByTripId['trip-1'] = expected;

      final result = await GetLocationsByTripIdUsecase(
        queryService,
      ).execute('trip-1');

      expect(result, expected);
      expect(queryService.requestedTripIds, ['trip-1']);
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

    test('場所を保存する', () async {
      const dto = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      await SaveLocationUsecase(repository).execute(dto);

      expect(repository.savedLocations.single, isA<Location>());
      expect(repository.savedLocations.single.id, dto.id);
      expect(repository.savedLocations.single.name, dto.name);
    });

    test('場所を削除する', () async {
      await DeleteLocationUsecase(repository).execute('location-1');

      expect(repository.deletedLocationIds, ['location-1']);
    });
  });
}

class _FakeLocationQueryService implements LocationQueryService {
  final locationsByTripId = <String, List<LocationDto>>{};
  final locationsByGroupId = <String, List<LocationDto>>{};
  final requestedTripIds = <String>[];
  final requestedGroupIds = <String>[];

  @override
  Future<List<LocationDto>> getLocationsByTripId(String tripId) async {
    requestedTripIds.add(tripId);
    return locationsByTripId[tripId] ?? const [];
  }

  @override
  Future<List<LocationDto>> getLocationsByGroupId(String groupId) async {
    requestedGroupIds.add(groupId);
    return locationsByGroupId[groupId] ?? const [];
  }
}

class _FakeLocationRepository implements LocationRepository {
  final savedLocations = <Location>[];
  final deletedLocationIds = <String>[];

  @override
  Future<void> saveLocation(Location location) async {
    savedLocations.add(location);
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    deletedLocationIds.add(locationId);
  }
}
