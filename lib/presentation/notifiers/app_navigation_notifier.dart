import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/app/app_route.dart';

final appNavigationNotifierProvider =
    NotifierProvider<AppNavigationNotifier, AppRoute>(
      AppNavigationNotifier.new,
    );

class AppNavigationNotifier extends Notifier<AppRoute> {
  @override
  AppRoute build() => const GroupTimelineGroupListDestination();

  void go(AppRoute route) {
    state = route;
  }

  void showLogin() {
    go(const AppLoginRoute());
  }

  void showSignup() {
    go(const AppSignupRoute());
  }

  void showGroupList() {
    go(const GroupTimelineGroupListDestination());
  }

  void showGroupTimeline(String groupId) {
    go(GroupTimelineOverviewDestination(groupId: groupId));
  }

  void showTripManagement({
    required String groupId,
    required int year,
    String? initialTripId,
  }) {
    go(
      GroupTimelineTripManagementDestination(
        groupId: groupId,
        year: year,
        initialTripId: initialTripId,
      ),
    );
  }

  bool goBack() {
    final parent = state.parent;
    if (parent == null) {
      return false;
    }
    state = parent;
    return true;
  }
}
