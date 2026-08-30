import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/trip/trip_entry_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/trip/trip_management_state.dart';

export 'trip_management_state.dart';

final tripManagementNotifierProvider = NotifierProvider.autoDispose
    .family<TripManagementNotifier, TripManagementState, TripManagementQuery>(
      TripManagementNotifier.new,
    );

class TripManagementNotifier extends Notifier<TripManagementState> {
  TripManagementNotifier(this._query);

  final TripManagementQuery _query;
  bool _isMutationInProgress = false;

  @override
  TripManagementState build() {
    Future.microtask(() => unawaited(_loadInitialData()));
    return const TripManagementState();
  }

  Future<bool> retryTripEntries() async {
    if (_isMutationInProgress || _isTripEntriesLoading) {
      return false;
    }
    await _loadTripEntries(isInitialLoad: false);
    return ref.mounted;
  }

  Future<bool> retryGroupMembers() async {
    if (_isGroupMembersLoading) {
      return false;
    }
    await _loadGroupMembers(isInitialLoad: false);
    return ref.mounted;
  }

  Future<bool> createTripEntry(TripEntryDto tripEntry) {
    return _runMutation(
      operationName: 'createTripEntry',
      execute: () async {
        await ref
            .read(tripEntryMutationCoordinatorProvider)
            .createTripEntry(tripEntry);
      },
    );
  }

  Future<bool> updateTripEntry(TripEntryDto tripEntry) {
    return _runMutation(
      operationName: 'updateTripEntry',
      execute: () => ref
          .read(tripEntryMutationCoordinatorProvider)
          .updateTripEntry(tripEntry),
    );
  }

  Future<bool> deleteTripEntry(String tripEntryId) {
    return _runMutation(
      operationName: 'deleteTripEntry',
      execute: () => ref
          .read(tripEntryMutationCoordinatorProvider)
          .deleteTripEntry(tripEntryId),
    );
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTripEntries(isInitialLoad: true),
      _loadGroupMembers(isInitialLoad: true),
    ]);
  }

  Future<void> _loadTripEntries({required bool isInitialLoad}) async {
    state = state.copyWith(
      tripEntriesStatus: isInitialLoad
          ? TripManagementLoadStatus.initialLoading
          : TripManagementLoadStatus.refreshing,
      clearTripEntriesError: true,
    );
    try {
      final tripEntries = await ref
          .read(getTripEntriesUsecaseProvider)
          .execute(_query.groupId, _query.year);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        tripEntries: tripEntries,
        tripEntriesStatus: TripManagementLoadStatus.success,
        clearTripEntriesError: true,
      );
    } catch (e, stack) {
      if (!ref.mounted) {
        return;
      }
      logger.e(
        'TripManagementNotifier.loadTripEntries: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        tripEntriesStatus: TripManagementLoadStatus.error,
        tripEntriesError: e,
      );
    }
  }

  Future<void> _loadGroupMembers({required bool isInitialLoad}) async {
    state = state.copyWith(
      groupMembersStatus: isInitialLoad
          ? TripManagementLoadStatus.initialLoading
          : TripManagementLoadStatus.refreshing,
      clearGroupMembersError: true,
    );
    try {
      final group = await ref
          .read(getGroupWithMembersByIdUsecaseProvider)
          .execute(_query.groupId, membersSort: GroupMemberSort.displayOrder);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        groupMembers: group?.members ?? const [],
        groupMembersStatus: TripManagementLoadStatus.success,
        clearGroupMembersError: true,
      );
    } catch (e, stack) {
      if (!ref.mounted) {
        return;
      }
      logger.e(
        'TripManagementNotifier.loadGroupMembers: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        groupMembersStatus: TripManagementLoadStatus.error,
        groupMembersError: e,
      );
    }
  }

  Future<bool> _runMutation({
    required String operationName,
    required Future<void> Function() execute,
  }) async {
    if (_isMutationInProgress || _isTripEntriesLoading) {
      return false;
    }

    _isMutationInProgress = true;
    final keepAliveLink = ref.keepAlive();
    try {
      try {
        await execute();
      } on ApplicationValidationException {
        rethrow;
      } catch (e, stack) {
        if (ref.mounted) {
          logger.e(
            'TripManagementNotifier.$operationName: ${e.toString()}',
            error: e,
            stackTrace: stack,
          );
        }
        rethrow;
      }
      if (!ref.mounted) {
        return false;
      }
      await _loadTripEntries(isInitialLoad: false);
      return ref.mounted;
    } finally {
      _isMutationInProgress = false;
      keepAliveLink.close();
    }
  }

  bool get _isTripEntriesLoading =>
      state.tripEntriesStatus == TripManagementLoadStatus.initialLoading ||
      state.tripEntriesStatus == TripManagementLoadStatus.refreshing;

  bool get _isGroupMembersLoading =>
      state.groupMembersStatus == TripManagementLoadStatus.initialLoading ||
      state.groupMembersStatus == TripManagementLoadStatus.refreshing;
}
