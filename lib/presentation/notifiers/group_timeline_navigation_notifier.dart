import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/app/app_route.dart';
import 'package:memora/presentation/notifiers/app_navigation_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

export 'package:memora/presentation/notifiers/group_timeline_destination.dart';

final groupTimelineNavigationNotifierProvider =
    NotifierProvider<
      GroupTimelineNavigationNotifier,
      GroupTimelineNavigationState
    >(GroupTimelineNavigationNotifier.new);

class GroupTimelineNavigationState {
  const GroupTimelineNavigationState({required this.destination});

  final GroupTimelineDestination destination;

  GroupTimelineScreenState get currentScreen => destination.screenState;

  String? get selectedGroupId => destination.groupId;

  int? get selectedYear => destination.year;
}

class GroupTimelineNavigationNotifier
    extends Notifier<GroupTimelineNavigationState> {
  @override
  GroupTimelineNavigationState build() {
    final route = ref.watch(appNavigationNotifierProvider);
    return GroupTimelineNavigationState(
      destination: switch (route) {
        GroupTimelineDestination() => route,
        AppDrawerRoute(:final returnRoute) => returnRoute,
        _ => const GroupTimelineGroupListDestination(),
      },
    );
  }

  void showGroupList() {
    ref.read(appNavigationNotifierProvider.notifier).showGroupList();
  }

  void showGroupTimeline(String groupId) {
    ref.read(appNavigationNotifierProvider.notifier).showGroupTimeline(groupId);
  }

  void showDestination(GroupTimelineDestination destination) {
    ref.read(appNavigationNotifierProvider.notifier).go(destination);
  }

  void showTripManagement(String groupId, int year, {String? initialTripId}) {
    showDestination(
      GroupTimelineTripManagementDestination(
        groupId: groupId,
        year: year,
        initialTripId: initialTripId,
      ),
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
    final groupId = state.destination.groupId;
    if (groupId == null) {
      showGroupList();
      return;
    }
    showGroupTimeline(groupId);
  }

  void resetToGroupList() {
    showGroupList();
  }

  bool canHandleBackNavigation() {
    return state.destination is! GroupTimelineGroupListDestination;
  }

  bool handleBackNavigation() {
    final destination = state.destination;
    if (destination is GroupTimelineGroupListDestination) {
      return false;
    }
    if (destination is GroupTimelineOverviewDestination) {
      showGroupList();
      return true;
    }
    backToTimeline();
    return true;
  }

  int getStackIndex() {
    return switch (state.destination) {
      GroupTimelineGroupListDestination() => 0,
      GroupTimelineOverviewDestination() => 1,
      GroupTimelineTripManagementDestination() => 2,
      GroupTimelineDvcPointCalculationDestination() => 3,
    };
  }
}
