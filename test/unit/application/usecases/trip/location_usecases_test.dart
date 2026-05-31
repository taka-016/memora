import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/application/usecases/trip/delete_location_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_member_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_trip_id_usecase.dart';
import 'package:memora/application/usecases/trip/save_location_usecase.dart';
import 'package:memora/application/usecases/trip/update_location_usecase.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';

void main() {
  group('LocationUsecases', () {
    late _FakeLocationQueryService queryService;
    late _FakeGroupQueryService groupQueryService;
    late _FakeLocationRepository repository;

    setUp(() {
      queryService = _FakeLocationQueryService();
      groupQueryService = _FakeGroupQueryService();
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

    test('メンバーIDで所属グループの場所一覧を取得する', () async {
      const group1 = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: '家族',
        members: [
          GroupMemberDto(
            groupId: 'group-1',
            memberId: 'member-1',
            displayName: 'テストメンバー',
            isAdministrator: true,
            orderIndex: 1,
          ),
        ],
      );
      const group2 = GroupDto(
        id: 'group-2',
        ownerId: 'owner-1',
        name: '友人',
        members: [
          GroupMemberDto(
            groupId: 'group-2',
            memberId: 'member-1',
            displayName: 'テストメンバー',
            isAdministrator: false,
            orderIndex: 1,
          ),
        ],
      );
      const location1 = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      const location2 = LocationDto(
        id: 'location-2',
        tripId: 'trip-2',
        groupId: 'group-2',
        name: '大阪駅',
        latitude: 34.6937,
        longitude: 135.5023,
      );
      groupQueryService.groupsByMemberId['member-1'] = [group1, group2];
      queryService.locationsByGroupId['group-1'] = [location1];
      queryService.locationsByGroupId['group-2'] = [location2];

      final result = await GetLocationsByMemberIdUsecase(
        groupQueryService,
        queryService,
      ).execute('member-1');

      expect(result, [location1, location2]);
      expect(groupQueryService.requestedMemberIds, ['member-1']);
      expect(queryService.requestedGroupIds, ['group-1', 'group-2']);
    });

    test('場所を追加する', () async {
      const dto = LocationDto(
        id: '',
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

    test('場所を更新する', () async {
      const dto = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      await UpdateLocationUsecase(repository).execute(dto);

      expect(repository.updatedLocations.single, isA<Location>());
      expect(repository.updatedLocations.single.id, dto.id);
      expect(repository.updatedLocations.single.name, dto.name);
    });

    test('場所を削除する', () async {
      await DeleteLocationUsecase(repository).execute('location-1');

      expect(repository.deletedLocationIds, ['location-1']);
    });
  });
}

class _FakeGroupQueryService implements GroupQueryService {
  final groupsByMemberId = <String, List<GroupDto>>{};
  final requestedMemberIds = <String>[];

  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    requestedMemberIds.add(memberId);
    return groupsByMemberId[memberId] ?? const [];
  }

  @override
  Future<List<GroupDto>> getManagedGroupsWithMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupDto?> getGroupWithMembersById(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) {
    throw UnimplementedError();
  }
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
  final updatedLocations = <Location>[];
  final deletedLocationIds = <String>[];

  @override
  Future<void> saveLocation(Location location) async {
    savedLocations.add(location);
  }

  @override
  Future<void> updateLocation(Location location) async {
    updatedLocations.add(location);
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    deletedLocationIds.add(locationId);
  }
}
