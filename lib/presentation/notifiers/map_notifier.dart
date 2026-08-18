import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/trip/trip_entry_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/map_state.dart';

export 'map_state.dart';

final mapNotifierProvider = NotifierProvider.autoDispose
    .family<MapNotifier, MapState, MemberDto>(MapNotifier.new);

class MapNotifier extends Notifier<MapState> {
  MapNotifier(this._currentMember);

  final MemberDto _currentMember;
  int _groupDataRequestId = 0;

  @override
  MapState build() {
    Future.microtask(() => unawaited(loadGroups()));
    return const MapState();
  }

  Future<void> loadGroups() async {
    if (state.groupsStatus == MapLoadStatus.loading) {
      return;
    }

    state = state.copyWith(groupsStatus: MapLoadStatus.loading);
    try {
      final groups = await ref
          .read(getGroupsWithMembersUsecaseProvider)
          .execute(_currentMember);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        groups: groups,
        groupsStatus: MapLoadStatus.success,
        clearSelectedGroup: state.selectedGroup != null,
      );
      if (groups.length == 1) {
        await selectGroup(groups.single);
      }
    } catch (e, stack) {
      if (!ref.mounted) {
        return;
      }
      logger.e(
        'MapNotifier.loadGroups: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(groupsStatus: MapLoadStatus.error);
    }
  }

  Future<void> selectGroup(GroupDto group) async {
    state = state.copyWith(
      selectedGroup: group,
      locations: const [],
      trips: const [],
      locationsStatus: MapLoadStatus.initial,
      tripsStatus: MapLoadStatus.initial,
      locationsErrorMessage: '',
      tripsErrorMessage: '',
    );
    await _loadSelectedGroupData(preserveData: false);
  }

  Future<void> retryGroupData() async {
    if (state.selectedGroup == null || state.isGroupDataLoading) {
      return;
    }
    await _loadSelectedGroupData(preserveData: true);
  }

  Future<TripEntryDto?> loadTripDetail(String tripId) async {
    try {
      final trip = await ref
          .read(getTripEntryByIdUsecaseProvider)
          .execute(tripId);
      if (!ref.mounted) {
        return null;
      }
      return trip;
    } catch (e, stack) {
      if (!ref.mounted) {
        return null;
      }
      logger.e(
        'MapNotifier.loadTripDetail: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<bool> updateTripEntry(TripEntryDto tripEntry) async {
    final keepAliveLink = ref.keepAlive();
    try {
      await ref
          .read(tripEntryMutationCoordinatorProvider)
          .updateTripEntry(tripEntry);
      if (!ref.mounted) {
        return false;
      }
      await _loadSelectedGroupData(preserveData: true);
      return ref.mounted;
    } catch (e, stack) {
      if (ref.mounted) {
        logger.e(
          'MapNotifier.updateTripEntry: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> _loadSelectedGroupData({required bool preserveData}) async {
    final group = state.selectedGroup;
    if (group == null) {
      return;
    }

    final requestId = ++_groupDataRequestId;
    state = state.copyWith(
      locations: preserveData ? state.locations : const [],
      trips: preserveData ? state.trips : const [],
      locationsStatus: MapLoadStatus.loading,
      tripsStatus: MapLoadStatus.loading,
      locationsErrorMessage: '',
      tripsErrorMessage: '',
    );

    await Future.wait([
      _loadLocations(group.id, requestId),
      _loadTrips(group.id, requestId),
    ]);
  }

  Future<void> _loadLocations(String groupId, int requestId) async {
    try {
      final locations = await ref
          .read(getLocationsByGroupIdUsecaseProvider)
          .execute(groupId);
      if (!_isCurrentRequest(groupId, requestId)) {
        return;
      }
      state = state.copyWith(
        locations: locations,
        locationsStatus: MapLoadStatus.success,
        locationsErrorMessage: '',
      );
    } catch (e, stack) {
      if (!_isCurrentRequest(groupId, requestId)) {
        return;
      }
      logger.e(
        'MapNotifier.loadLocations: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        locationsStatus: MapLoadStatus.error,
        locationsErrorMessage: '訪問場所の取得に失敗しました',
      );
    }
  }

  Future<void> _loadTrips(String groupId, int requestId) async {
    try {
      final trips = await ref
          .read(getMapTripEntriesUsecaseProvider)
          .executeByGroupId(groupId);
      if (!_isCurrentRequest(groupId, requestId)) {
        return;
      }
      state = state.copyWith(
        trips: trips,
        tripsStatus: MapLoadStatus.success,
        tripsErrorMessage: '',
      );
    } catch (e, stack) {
      if (!_isCurrentRequest(groupId, requestId)) {
        return;
      }
      logger.e(
        'MapNotifier.loadTrips: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        tripsStatus: MapLoadStatus.error,
        tripsErrorMessage: '旅行情報の取得に失敗しました',
      );
    }
  }

  bool _isCurrentRequest(String groupId, int requestId) {
    return ref.mounted &&
        requestId == _groupDataRequestId &&
        state.selectedGroup?.id == groupId;
  }
}
