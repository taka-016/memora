import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/presentation/notifiers/map/map_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'map_notifier_test.mocks.dart';

@GenerateMocks([
  GetGroupsWithMembersUsecase,
  GetLocationsByGroupIdUsecase,
  GetTripEntriesUsecase,
  UpdateTripEntryUsecase,
])
void main() {
  const currentMember = MemberDto(id: 'member-1', displayName: '太郎');
  const firstGroup = GroupDto(
    id: 'group-1',
    ownerId: 'member-1',
    name: '家族',
    members: [],
  );
  const secondGroup = GroupDto(
    id: 'group-2',
    ownerId: 'member-1',
    name: '友人',
    members: [],
  );
  const firstLocation = LocationDto(
    id: 'location-1',
    tripId: 'trip-1',
    groupId: 'group-1',
    latitude: 35,
    longitude: 139,
    name: '東京',
  );
  const secondLocation = LocationDto(
    id: 'location-2',
    tripId: 'trip-2',
    groupId: 'group-2',
    latitude: 34,
    longitude: 135,
    name: '大阪',
  );
  const firstTrip = TripEntryDto(
    id: 'trip-1',
    groupId: 'group-1',
    year: 2026,
    name: '東京旅行',
  );
  const secondTrip = TripEntryDto(
    id: 'trip-2',
    groupId: 'group-2',
    year: 2026,
    name: '大阪旅行',
  );

  late MockGetGroupsWithMembersUsecase getGroupsUsecase;
  late MockGetLocationsByGroupIdUsecase getLocationsUsecase;
  late MockGetTripEntriesUsecase getTripsUsecase;
  late MockUpdateTripEntryUsecase updateTripUsecase;
  late ProviderContainer container;

  setUp(() {
    getGroupsUsecase = MockGetGroupsWithMembersUsecase();
    getLocationsUsecase = MockGetLocationsByGroupIdUsecase();
    getTripsUsecase = MockGetTripEntriesUsecase();
    updateTripUsecase = MockUpdateTripEntryUsecase();
    container = ProviderContainer(
      overrides: [
        getGroupsWithMembersUsecaseProvider.overrideWithValue(getGroupsUsecase),
        getLocationsByGroupIdUsecaseProvider.overrideWithValue(
          getLocationsUsecase,
        ),
        getMapTripEntriesUsecaseProvider.overrideWithValue(getTripsUsecase),
        updateTripEntryUsecaseProvider.overrideWithValue(updateTripUsecase),
      ],
    );
    when(getLocationsUsecase.execute(any)).thenAnswer((_) async => const []);
    when(
      getTripsUsecase.executeByGroupId(any),
    ).thenAnswer((_) async => const []);
  });

  tearDown(() {
    container.dispose();
  });

  Future<MapNotifier> startNotifier({
    List<GroupDto> groups = const [firstGroup],
  }) async {
    when(
      getGroupsUsecase.execute(currentMember),
    ).thenAnswer((_) async => groups);
    final provider = mapNotifierProvider(currentMember);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final notifier = container.read(provider.notifier);
    await notifier.loadGroups();
    return notifier;
  }

  group('MapNotifier', () {
    test('所属グループが1件なら自動選択して訪問場所と旅行を取得する', () async {
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [firstGroup]);
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) async => const [firstLocation]);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenAnswer((_) async => const [firstTrip]);
      final provider = mapNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final notifier = container.read(provider.notifier);

      await notifier.loadGroups();

      final state = container.read(provider);
      expect(state.groupsStatus, MapLoadStatus.success);
      expect(state.selectedGroup, firstGroup);
      expect(state.locations, const [firstLocation]);
      expect(state.trips, const [firstTrip]);
      expect(state.locationsStatus, MapLoadStatus.success);
      expect(state.tripsStatus, MapLoadStatus.success);
    });

    test('グループ切り替え後に完了した古い取得結果を破棄する', () async {
      final firstLocationsCompleter = Completer<List<LocationDto>>();
      final firstTripsCompleter = Completer<List<TripEntryDto>>();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [firstGroup, secondGroup]);
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) => firstLocationsCompleter.future);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenAnswer((_) => firstTripsCompleter.future);
      when(
        getLocationsUsecase.execute(secondGroup.id),
      ).thenAnswer((_) async => const [secondLocation]);
      when(
        getTripsUsecase.executeByGroupId(secondGroup.id),
      ).thenAnswer((_) async => const [secondTrip]);
      final notifier = await startNotifier(
        groups: const [firstGroup, secondGroup],
      );

      final firstSelection = notifier.selectGroup(firstGroup);
      final secondSelection = notifier.selectGroup(secondGroup);
      await secondSelection;
      firstLocationsCompleter.complete(const [firstLocation]);
      firstTripsCompleter.complete(const [firstTrip]);
      await firstSelection;

      final state = container.read(mapNotifierProvider(currentMember));
      expect(state.selectedGroup, secondGroup);
      expect(state.locations, const [secondLocation]);
      expect(state.trips, const [secondTrip]);
    });

    test('訪問場所取得だけが失敗しても旅行取得結果を維持する', () async {
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenThrow(TestException('訪問場所取得失敗'));
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenAnswer((_) async => const [firstTrip]);

      await startNotifier();

      final state = container.read(mapNotifierProvider(currentMember));
      expect(state.locationsStatus, MapLoadStatus.error);
      expect(state.locations, isEmpty);
      expect(state.tripsStatus, MapLoadStatus.success);
      expect(state.trips, const [firstTrip]);
    });

    test('旅行取得だけが失敗しても訪問場所取得結果を維持する', () async {
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) async => const [firstLocation]);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenThrow(TestException('旅行取得失敗'));

      await startNotifier();

      final state = container.read(mapNotifierProvider(currentMember));
      expect(state.locationsStatus, MapLoadStatus.success);
      expect(state.locations, const [firstLocation]);
      expect(state.tripsStatus, MapLoadStatus.error);
      expect(state.trips, isEmpty);
    });

    test('再試行時は失敗していない既存データを維持し両方を再取得する', () async {
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) async => const [firstLocation]);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenThrow(TestException('旅行取得失敗'));
      final notifier = await startNotifier();
      final retryLocationsCompleter = Completer<List<LocationDto>>();
      final retryTripsCompleter = Completer<List<TripEntryDto>>();
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) => retryLocationsCompleter.future);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenAnswer((_) => retryTripsCompleter.future);

      final retryFuture = notifier.retryGroupData();

      var state = container.read(mapNotifierProvider(currentMember));
      expect(state.locations, const [firstLocation]);
      expect(state.locationsStatus, MapLoadStatus.loading);
      expect(state.tripsStatus, MapLoadStatus.loading);
      retryLocationsCompleter.complete(const [secondLocation]);
      retryTripsCompleter.complete(const [secondTrip]);
      await retryFuture;

      state = container.read(mapNotifierProvider(currentMember));
      expect(state.locations, const [secondLocation]);
      expect(state.trips, const [secondTrip]);
      verify(getLocationsUsecase.execute(firstGroup.id)).called(2);
      verify(getTripsUsecase.executeByGroupId(firstGroup.id)).called(2);
    });

    test('旅行更新後に旅行一覧と訪問場所一覧を再取得する', () async {
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) async => const [firstLocation]);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenAnswer((_) async => const [firstTrip]);
      final notifier = await startNotifier();
      final updatedTrip = firstTrip.copyWith(
        name: '更新後の東京旅行',
        locations: const [secondLocation],
      );
      when(updateTripUsecase.execute(updatedTrip)).thenAnswer((_) async {});
      when(
        getLocationsUsecase.execute(firstGroup.id),
      ).thenAnswer((_) async => const [secondLocation]);
      when(
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ).thenAnswer((_) async => [updatedTrip]);

      final result = await notifier.updateTripEntry(updatedTrip);

      final state = container.read(mapNotifierProvider(currentMember));
      expect(result, isTrue);
      expect(state.locations, const [secondLocation]);
      expect(state.trips, [updatedTrip]);
      verifyInOrder([
        updateTripUsecase.execute(updatedTrip),
        getLocationsUsecase.execute(firstGroup.id),
        getTripsUsecase.executeByGroupId(firstGroup.id),
      ]);
    });
  });
}
