import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/app/app_route.dart';
import 'package:memora/presentation/notifiers/app_navigation_notifier.dart';

enum NavigationItem {
  groupTimeline,
  mapDisplay,
  groupManagement,
  memberManagement,
  settings,
  accountSettings,
}

final navigationNotifierProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
      NavigationNotifier.new,
    );

class NavigationState {
  final NavigationItem selectedItem;

  const NavigationState({required this.selectedItem});

  NavigationState copyWith({NavigationItem? selectedItem}) {
    return NavigationState(selectedItem: selectedItem ?? this.selectedItem);
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    final route = ref.watch(appNavigationNotifierProvider);
    return NavigationState(selectedItem: _itemForRoute(route));
  }

  void selectItem(NavigationItem item) {
    final currentRoute = ref.read(appNavigationNotifierProvider);
    ref
        .read(appNavigationNotifierProvider.notifier)
        .go(_routeForItem(item, _returnRouteFor(currentRoute)));
  }

  void resetToDefault() {
    ref.read(appNavigationNotifierProvider.notifier).showGroupList();
  }

  NavigationItem _itemForRoute(AppRoute route) {
    return switch (route) {
      AppMapRoute() => NavigationItem.mapDisplay,
      AppGroupManagementRoute() => NavigationItem.groupManagement,
      AppMemberManagementRoute() => NavigationItem.memberManagement,
      AppSettingsRoute() => NavigationItem.settings,
      AppAccountSettingsRoute() => NavigationItem.accountSettings,
      _ => NavigationItem.groupTimeline,
    };
  }

  GroupTimelineDestination _returnRouteFor(AppRoute route) {
    return switch (route) {
      GroupTimelineDestination() => route,
      AppDrawerRoute(:final returnRoute) => returnRoute,
      _ => const GroupTimelineGroupListDestination(),
    };
  }

  AppRoute _routeForItem(
    NavigationItem item,
    GroupTimelineDestination returnRoute,
  ) {
    return switch (item) {
      NavigationItem.groupTimeline => const GroupTimelineGroupListDestination(),
      NavigationItem.mapDisplay => AppMapRoute(returnRoute: returnRoute),
      NavigationItem.groupManagement => AppGroupManagementRoute(
        returnRoute: returnRoute,
      ),
      NavigationItem.memberManagement => AppMemberManagementRoute(
        returnRoute: returnRoute,
      ),
      NavigationItem.settings => AppSettingsRoute(returnRoute: returnRoute),
      NavigationItem.accountSettings => AppAccountSettingsRoute(
        returnRoute: returnRoute,
      ),
    };
  }
}
