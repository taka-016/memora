sealed class AppRoute {
  const AppRoute();

  AppRoute? get parent => null;
}

class AppLoadingRoute extends AppRoute {
  const AppLoadingRoute();

  @override
  bool operator ==(Object other) => other is AppLoadingRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AppLoginRoute extends AppRoute {
  const AppLoginRoute();

  @override
  bool operator ==(Object other) => other is AppLoginRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AppSignupRoute extends AppRoute {
  const AppSignupRoute();

  @override
  AppRoute get parent => const AppLoginRoute();

  @override
  bool operator ==(Object other) => other is AppSignupRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AppMemberSetupRoute extends AppRoute {
  const AppMemberSetupRoute();

  @override
  bool operator ==(Object other) => other is AppMemberSetupRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

enum GroupTimelineScreenState {
  groupList,
  timeline,
  tripManagement,
  dvcPointCalculation,
}

sealed class GroupTimelineDestination extends AppRoute {
  const GroupTimelineDestination();

  GroupTimelineScreenState get screenState;

  String? get groupId => null;

  int? get year => null;
}

class GroupTimelineGroupListDestination extends GroupTimelineDestination {
  const GroupTimelineGroupListDestination();

  @override
  GroupTimelineScreenState get screenState =>
      GroupTimelineScreenState.groupList;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupTimelineGroupListDestination;

  @override
  int get hashCode => screenState.hashCode;
}

class GroupTimelineOverviewDestination extends GroupTimelineDestination {
  const GroupTimelineOverviewDestination({required this.groupId});

  @override
  final String groupId;

  @override
  GroupTimelineScreenState get screenState => GroupTimelineScreenState.timeline;

  @override
  AppRoute get parent => const GroupTimelineGroupListDestination();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupTimelineOverviewDestination && other.groupId == groupId;

  @override
  int get hashCode => Object.hash(screenState, groupId);
}

class GroupTimelineTripManagementDestination extends GroupTimelineDestination {
  const GroupTimelineTripManagementDestination({
    required this.groupId,
    required this.year,
    this.initialTripId,
  });

  @override
  final String groupId;

  @override
  final int year;
  final String? initialTripId;

  @override
  GroupTimelineScreenState get screenState =>
      GroupTimelineScreenState.tripManagement;

  @override
  AppRoute get parent => GroupTimelineOverviewDestination(groupId: groupId);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GroupTimelineTripManagementDestination &&
            other.groupId == groupId &&
            other.year == year &&
            other.initialTripId == initialTripId;
  }

  @override
  int get hashCode => Object.hash(screenState, groupId, year, initialTripId);
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
  AppRoute get parent => GroupTimelineOverviewDestination(groupId: groupId);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GroupTimelineDvcPointCalculationDestination &&
            other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(screenState, groupId);
}

sealed class AppDrawerRoute extends AppRoute {
  const AppDrawerRoute({
    this.returnRoute = const GroupTimelineGroupListDestination(),
  });

  final GroupTimelineDestination returnRoute;

  @override
  AppRoute get parent => returnRoute;
}

class AppMapRoute extends AppDrawerRoute {
  const AppMapRoute({super.returnRoute});

  @override
  bool operator ==(Object other) =>
      other is AppMapRoute && other.returnRoute == returnRoute;

  @override
  int get hashCode => Object.hash(runtimeType, returnRoute);
}

class AppMemberManagementRoute extends AppDrawerRoute {
  const AppMemberManagementRoute({super.returnRoute});

  @override
  bool operator ==(Object other) =>
      other is AppMemberManagementRoute && other.returnRoute == returnRoute;

  @override
  int get hashCode => Object.hash(runtimeType, returnRoute);
}

class AppGroupManagementRoute extends AppDrawerRoute {
  const AppGroupManagementRoute({super.returnRoute});

  @override
  bool operator ==(Object other) =>
      other is AppGroupManagementRoute && other.returnRoute == returnRoute;

  @override
  int get hashCode => Object.hash(runtimeType, returnRoute);
}

class AppSettingsRoute extends AppDrawerRoute {
  const AppSettingsRoute({super.returnRoute});

  @override
  bool operator ==(Object other) =>
      other is AppSettingsRoute && other.returnRoute == returnRoute;

  @override
  int get hashCode => Object.hash(runtimeType, returnRoute);
}

class AppAccountSettingsRoute extends AppDrawerRoute {
  const AppAccountSettingsRoute({super.returnRoute});

  @override
  bool operator ==(Object other) =>
      other is AppAccountSettingsRoute && other.returnRoute == returnRoute;

  @override
  int get hashCode => Object.hash(runtimeType, returnRoute);
}
