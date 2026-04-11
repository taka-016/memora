enum GroupTimelineScreenState {
  groupList,
  timeline,
  tripManagement,
  dvcPointCalculation,
}

sealed class GroupTimelineDestination {
  const GroupTimelineDestination();

  GroupTimelineScreenState get screenState;

  int get stackIndex;

  String? get groupId => null;

  int? get year => null;
}

class GroupTimelineGroupListDestination extends GroupTimelineDestination {
  const GroupTimelineGroupListDestination();

  @override
  GroupTimelineScreenState get screenState =>
      GroupTimelineScreenState.groupList;

  @override
  int get stackIndex => 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupTimelineGroupListDestination;

  @override
  int get hashCode => screenState.hashCode;
}

class GroupTimelineTimelineDestination extends GroupTimelineDestination {
  const GroupTimelineTimelineDestination();

  @override
  GroupTimelineScreenState get screenState => GroupTimelineScreenState.timeline;

  @override
  int get stackIndex => 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupTimelineTimelineDestination;

  @override
  int get hashCode => screenState.hashCode;
}

class GroupTimelineTripManagementDestination extends GroupTimelineDestination {
  const GroupTimelineTripManagementDestination({
    required this.groupId,
    required this.year,
  });

  @override
  final String groupId;

  @override
  final int year;

  @override
  GroupTimelineScreenState get screenState =>
      GroupTimelineScreenState.tripManagement;

  @override
  int get stackIndex => 2;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GroupTimelineTripManagementDestination &&
            other.groupId == groupId &&
            other.year == year;
  }

  @override
  int get hashCode => Object.hash(screenState, groupId, year);
}

class GroupTimelineDvcPointCalculationDestination
    extends GroupTimelineDestination {
  const GroupTimelineDvcPointCalculationDestination({required this.groupId});

  @override
  final String groupId;

  @override
  GroupTimelineScreenState get screenState =>
      GroupTimelineScreenState.dvcPointCalculation;

  @override
  int get stackIndex => 3;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GroupTimelineDvcPointCalculationDestination &&
            other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(screenState, groupId);
}
