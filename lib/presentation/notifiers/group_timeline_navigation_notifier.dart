import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/timeline/default_timeline_rows.dart';
import 'package:memora/presentation/features/timeline/timeline.dart';
import 'package:memora/presentation/features/timeline/timeline_destination_page_definition.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
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
  final List<TimelineRowDefinition> timelineRowDefinitions;
  final RefreshTimelineCallback? refreshGroupTimeline;

  const GroupTimelineNavigationState({
    required this.destination,
    this.groupTimelineInstance,
    this.timelineRowDefinitions = const [],
    this.refreshGroupTimeline,
  });

  GroupTimelineScreenState get currentScreen => destination.screenState;

  String? get selectedGroupId => destination.groupId;

  int? get selectedYear => destination.year;

  List<TimelineDestinationPageDefinition> get destinationPageDefinitions {
    return timelineRowDefinitions
        .expand((rowDefinition) => rowDefinition.destinationPageDefinitions)
        .toList(growable: false);
  }

  GroupTimelineNavigationState copyWith({
    GroupTimelineDestination? destination,
    Timeline? groupTimelineInstance,
    List<TimelineRowDefinition>? timelineRowDefinitions,
    RefreshTimelineCallback? refreshGroupTimeline,
    bool clearInstance = false,
    bool clearRowDefinitions = false,
    bool clearRefresh = false,
  }) {
    return GroupTimelineNavigationState(
      destination: destination ?? this.destination,
      groupTimelineInstance: clearInstance
          ? null
          : (groupTimelineInstance ?? this.groupTimelineInstance),
      timelineRowDefinitions: clearRowDefinitions
          ? const []
          : (timelineRowDefinitions ?? this.timelineRowDefinitions),
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
    final rowDefinitions = buildDefaultTimelineRows(
      groupWithMembers: groupWithMembers,
      onDestinationSelected: showDestination,
    );
    late final Timeline groupTimeline;
    groupTimeline = Timeline(
      groupWithMembers: groupWithMembers,
      rowDefinitions: rowDefinitions,
      onBackPressed: showGroupList,
      onSetRefreshCallback: (callback) {
        Future(() {
          if (state.destination is! GroupTimelineOverviewDestination ||
              state.groupTimelineInstance != groupTimeline) {
            return;
          }
          state = state.copyWith(refreshGroupTimeline: callback);
        });
      },
    );

    state = state.copyWith(
      destination: const GroupTimelineOverviewDestination(),
      groupTimelineInstance: groupTimeline,
      timelineRowDefinitions: rowDefinitions,
      clearRefresh: true,
    );
  }

  void showDestination(GroupTimelineDestination destination) {
    state = state.copyWith(destination: normalizeDestination(destination));
  }

  void showTripManagement(String groupId, int year) {
    showDestination(
      GroupTimelineTripManagementDestination(groupId: groupId, year: year),
    );
  }

  void backFromTripManagement() {
    backToTimeline();
  }

  void showDvcPointCalculation(String selectedGroupId) {
    showDestination(
      GroupTimelineDvcPointCalculationDestination(groupId: selectedGroupId),
    );
  }

  void backFromDvcPointCalculation() {
    backToTimeline();
  }

  void backToTimeline() {
    state = state.copyWith(
      destination: const GroupTimelineOverviewDestination(),
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
      clearRowDefinitions: true,
      clearRefresh: true,
    );
  }

  bool canHandleBackNavigation() {
    return state.destination is! GroupTimelineGroupListDestination;
  }

  bool handleBackNavigation() {
    final destination = state.destination;
    final normalizedDestination = normalizeDestination(destination);
    if (normalizedDestination != destination) {
      state = state.copyWith(destination: normalizedDestination);
      return true;
    }

    final currentDestination = normalizedDestination;
    if (currentDestination is GroupTimelineGroupListDestination) {
      return false;
    }
    if (currentDestination is GroupTimelineOverviewDestination) {
      showGroupList();
      return true;
    }
    backToTimeline();
    return true;
  }

  int getStackIndex() {
    final destination = normalizeDestination(state.destination);
    if (destination is GroupTimelineGroupListDestination) {
      return 0;
    }
    if (destination is GroupTimelineOverviewDestination) {
      return 1;
    }

    final destinationPageIndex = state.destinationPageDefinitions.indexWhere(
      (definition) => definition.matches(destination),
    );
    if (destinationPageIndex == -1) {
      return fallbackDestination() is GroupTimelineOverviewDestination ? 1 : 0;
    }

    return destinationPageIndex + 2;
  }

  GroupTimelineDestination normalizeDestination(
    GroupTimelineDestination destination,
  ) {
    if (destination is GroupTimelineGroupListDestination ||
        destination is GroupTimelineOverviewDestination) {
      return destination;
    }
    final hasDestinationPage = state.destinationPageDefinitions.any(
      (definition) => definition.matches(destination),
    );
    if (hasDestinationPage) {
      return destination;
    }
    return fallbackDestination();
  }

  GroupTimelineDestination fallbackDestination() {
    if (state.groupTimelineInstance != null) {
      return const GroupTimelineOverviewDestination();
    }
    return const GroupTimelineGroupListDestination();
  }
}
