import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/group_with_members.dart';
import 'package:memora/presentation/features/timeline/group_timeline.dart';

enum GroupTimelineScreenState { groupList, timeline, tripManagement }

final groupTimelineNavigationControllerProvider =
    StateNotifierProvider<
      GroupTimelineNavigationController,
      GroupTimelineNavigationState
    >((ref) {
      return GroupTimelineNavigationController();
    });

class GroupTimelineNavigationState {
  final GroupTimelineScreenState currentScreen;
  final String? selectedGroupId;
  final int? selectedYear;
  final GroupTimeline? groupTimelineInstance;
  final VoidCallback? refreshGroupTimeline;

  const GroupTimelineNavigationState({
    required this.currentScreen,
    this.selectedGroupId,
    this.selectedYear,
    this.groupTimelineInstance,
    this.refreshGroupTimeline,
  });

  GroupTimelineNavigationState copyWith({
    GroupTimelineScreenState? currentScreen,
    String? selectedGroupId,
    int? selectedYear,
    GroupTimeline? groupTimelineInstance,
    VoidCallback? refreshGroupTimeline,
    bool clearGroupId = false,
    bool clearYear = false,
    bool clearInstance = false,
    bool clearRefresh = false,
  }) {
    return GroupTimelineNavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      selectedGroupId: clearGroupId
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      groupTimelineInstance: clearInstance
          ? null
          : (groupTimelineInstance ?? this.groupTimelineInstance),
      refreshGroupTimeline: clearRefresh
          ? null
          : (refreshGroupTimeline ?? this.refreshGroupTimeline),
    );
  }
}

class GroupTimelineNavigationController
    extends StateNotifier<GroupTimelineNavigationState> {
  GroupTimelineNavigationController()
    : super(
        const GroupTimelineNavigationState(
          currentScreen: GroupTimelineScreenState.groupList,
        ),
      );

  void showGroupList() {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.groupList,
      clearInstance: true,
    );
  }

  void showGroupTimeline(GroupWithMembers groupWithMembers) {
    final groupTimeline = GroupTimeline(
      groupWithMembers: groupWithMembers,
      onBackPressed: showGroupList,
      onTripManagementSelected: showTripManagement,
      onSetRefreshCallback: (callback) {
        Future(() {
          state = state.copyWith(refreshGroupTimeline: callback);
        });
      },
    );

    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.timeline,
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

  void resetToGroupList() {
    state = state.copyWith(
      currentScreen: GroupTimelineScreenState.groupList,
      clearGroupId: true,
      clearYear: true,
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
    }
  }
}
