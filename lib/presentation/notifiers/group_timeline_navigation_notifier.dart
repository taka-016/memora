import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/group_timeline.dart';

enum GroupTimelineScreenState {
  groupList,
  timeline,
  tripManagement,
  dvcPointCalculation,
}

final groupTimelineNavigationNotifierProvider =
    NotifierProvider<
      GroupTimelineNavigationNotifier,
      GroupTimelineNavigationState
    >(GroupTimelineNavigationNotifier.new);

class GroupTimelineNavigationState {
  final GroupTimelineScreenState currentScreen;
  final String? selectedGroupId;
  final int? selectedYear;
  final String? selectedDvcGroupId;
  final GroupTimeline? groupTimelineInstance;
  final VoidCallback? refreshGroupTimeline;

  const GroupTimelineNavigationState({
    required this.currentScreen,
    this.selectedGroupId,
    this.selectedYear,
    this.selectedDvcGroupId,
    this.groupTimelineInstance,
    this.refreshGroupTimeline,
  });

  GroupTimelineNavigationState copyWith({
    GroupTimelineScreenState? currentScreen,
    String? selectedGroupId,
    int? selectedYear,
    String? selectedDvcGroupId,
    GroupTimeline? groupTimelineInstance,
    VoidCallback? refreshGroupTimeline,
    bool clearGroupId = false,
    bool clearYear = false,
    bool clearDvcGroupId = false,
    bool clearInstance = false,
    bool clearRefresh = false,
  }) {
    return GroupTimelineNavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      selectedGroupId: clearGroupId
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      selectedDvcGroupId: clearDvcGroupId
          ? null
          : (selectedDvcGroupId ?? this.selectedDvcGroupId),
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
      currentScreen: GroupTimelineScreenState.groupList,
    );
  }

  void showGroupList() {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.groupList,
      clearDvcGroupId: true,
      clearInstance: true,
    );
  }

  void showGroupTimeline(GroupDto groupWithMembers) {
    final groupTimeline = GroupTimeline(
      groupWithMembers: groupWithMembers,
      onBackPressed: showGroupList,
      onTripManagementSelected: showTripManagement,
      onDvcPointCalculationPressed: () =>
          showDvcPointCalculation(groupWithMembers.id),
      onSetRefreshCallback: (callback) {
        Future(() {
          state = state.copyWith(refreshGroupTimeline: callback);
        });
      },
    );

    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.timeline,
      clearDvcGroupId: true,
      groupTimelineInstance: groupTimeline,
    );
  }

  void showTripManagement(String groupId, int year) {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.tripManagement,
      selectedGroupId: groupId,
      selectedYear: year,
    );
  }

  void backFromTripManagement() {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.timeline,
      clearGroupId: true,
      clearYear: true,
    );

    state.refreshGroupTimeline?.call();
  }

  void showDvcPointCalculation(String selectedDvcGroupId) {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.dvcPointCalculation,
      selectedDvcGroupId: selectedDvcGroupId,
    );
  }

  void backFromDvcPointCalculation() {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.timeline,
      clearDvcGroupId: true,
    );
  }

  void resetToGroupList() {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.groupList,
      clearGroupId: true,
      clearYear: true,
      clearDvcGroupId: true,
      clearInstance: true,
      clearRefresh: true,
    );
  }

  int getStackIndex() {
    switch (state.currentScreen) {
      case GroupTimelineScreenState.groupList:
        return 0;
      case GroupTimelineScreenState.timeline:
        return 1;
      case GroupTimelineScreenState.tripManagement:
        return 2;
      case GroupTimelineScreenState.dvcPointCalculation:
        return 3;
    }
  }
}
