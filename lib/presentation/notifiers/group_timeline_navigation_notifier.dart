import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/default_timeline_rows.dart';
import 'package:memora/presentation/features/timeline/timeline.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

export 'package:memora/presentation/notifiers/group_timeline_destination.dart';

final groupTimelineNavigationNotifierProvider =
    NotifierProvider<
      GroupTimelineNavigationNotifier,
      GroupTimelineNavigationState
    >(GroupTimelineNavigationNotifier.new);

class GroupTimelineNavigationState {
  final GroupTimelineDestination destination;
  final Timeline? groupTimelineInstance;
  final RefreshTimelineCallback? refreshGroupTimeline;

  const GroupTimelineNavigationState({
    required this.destination,
    this.groupTimelineInstance,
    this.refreshGroupTimeline,
  });

  GroupTimelineScreenState get currentScreen => destination.screenState;

  String? get selectedGroupId => destination.groupId;

  int? get selectedYear => destination.year;

  GroupTimelineNavigationState copyWith({
    GroupTimelineDestination? destination,
    Timeline? groupTimelineInstance,
    RefreshTimelineCallback? refreshGroupTimeline,
    bool clearInstance = false,
    bool clearRefresh = false,
  }) {
    return GroupTimelineNavigationState(
      destination: destination ?? this.destination,
      groupTimelineInstance: clearInstance
          ? null
          : (groupTimelineInstance ?? this.groupTimelineInstance),
      refreshGroupTimeline: clearRefresh
          ? null
          : (refreshGroupTimeline ?? this.refreshGroupTimeline),
    );
  }
}

class GroupTimelineNavigationNotifier
    extends Notifier<GroupTimelineNavigationState> {
  @override
  GroupTimelineNavigationState build() {
    return const GroupTimelineNavigationState(
      destination: GroupTimelineGroupListDestination(),
    );
  }

  void showGroupList() {
    resetToGroupList();
  }

  void showGroupTimeline(GroupDto groupWithMembers) {
    late final Timeline groupTimeline;
    groupTimeline = Timeline(
      groupWithMembers: groupWithMembers,
      rowDefinitions: buildDefaultTimelineRows(
        groupWithMembers: groupWithMembers,
        onDestinationSelected: showDestination,
      ),
      onBackPressed: showGroupList,
      onSetRefreshCallback: (callback) {
        Future(() {
          if (state.destination is! GroupTimelineTimelineDestination ||
              state.groupTimelineInstance != groupTimeline) {
            return;
          }
          state = state.copyWith(refreshGroupTimeline: callback);
        });
      },
    );

    state = state.copyWith(
      destination: const GroupTimelineTimelineDestination(),
      groupTimelineInstance: groupTimeline,
    );
  }

  void showDestination(GroupTimelineDestination destination) {
    state = state.copyWith(destination: destination);
  }

  void showTripManagement(String groupId, int year) {
    showDestination(
      GroupTimelineTripManagementDestination(groupId: groupId, year: year),
    );
  }

  void backFromTripManagement() {
    state = state.copyWith(
      destination: const GroupTimelineTimelineDestination(),
    );

    final refreshGroupTimeline = state.refreshGroupTimeline;
    if (refreshGroupTimeline != null) {
      unawaited(refreshGroupTimeline());
    }
  }

  void showDvcPointCalculation(String selectedGroupId) {
    showDestination(
      GroupTimelineDvcPointCalculationDestination(groupId: selectedGroupId),
    );
  }

  void backFromDvcPointCalculation() {
    state = state.copyWith(
      destination: const GroupTimelineTimelineDestination(),
    );

    final refreshGroupTimeline = state.refreshGroupTimeline;
    if (refreshGroupTimeline != null) {
      unawaited(refreshGroupTimeline());
    }
  }

  void resetToGroupList() {
    state = state.copyWith(
      destination: const GroupTimelineGroupListDestination(),
      clearInstance: true,
      clearRefresh: true,
    );
  }

  bool canHandleBackNavigation() {
    return state.destination is! GroupTimelineGroupListDestination;
  }

  bool handleBackNavigation() {
    final destination = state.destination;
    if (destination is GroupTimelineGroupListDestination) {
      return false;
    }
    if (destination is GroupTimelineTimelineDestination) {
      showGroupList();
      return true;
    }

    if (destination is GroupTimelineTripManagementDestination) {
      backFromTripManagement();
      return true;
    }

    if (destination is GroupTimelineDvcPointCalculationDestination) {
      backFromDvcPointCalculation();
      return true;
    }

    return false;
  }

  int getStackIndex() {
    return state.destination.stackIndex;
  }
}
