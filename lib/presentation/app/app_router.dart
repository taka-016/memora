import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/app/app_route.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:memora/presentation/features/auth/auth_guard.dart';
import 'package:memora/presentation/features/auth/login_page.dart';
import 'package:memora/presentation/features/auth/signup_page.dart';
import 'package:memora/presentation/notifiers/app_navigation_notifier.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

final appRouterDelegateProvider = Provider<AppRouterDelegate>((ref) {
  final delegate = AppRouterDelegate(ref);
  ref.listen<AppRoute>(appNavigationNotifierProvider, (_, _) {
    delegate.refresh();
  });
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    if (previous?.isAuthenticated ?? false && !next.isAuthenticated) {
      ref.read(appNavigationNotifierProvider.notifier).showGroupList();
    }
    delegate.refresh();
  });
  ref.onDispose(delegate.dispose);
  return delegate;
});

final appRouterConfigProvider = Provider<RouterConfig<AppRoute>>((ref) {
  final initialRoute = Uri.tryParse(
    WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );
  final routeInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(
      uri: initialRoute ?? Uri(path: '/groups'),
    ),
  );
  ref.onDispose(routeInformationProvider.dispose);
  return RouterConfig<AppRoute>(
    routerDelegate: ref.watch(appRouterDelegateProvider),
    routeInformationProvider: routeInformationProvider,
    routeInformationParser: const AppRouteInformationParser(),
  );
});

AppRoute resolveAppRoute(AuthState authState, AppRoute requestedRoute) {
  if (authState.isLoading) {
    return const AppLoadingRoute();
  }
  if (authState.requiresMemberSelection) {
    return const AppMemberSetupRoute();
  }
  if (!authState.isAuthenticated) {
    return requestedRoute is AppSignupRoute
        ? requestedRoute
        : const AppLoginRoute();
  }
  if (requestedRoute is AppLoginRoute ||
      requestedRoute is AppSignupRoute ||
      requestedRoute is AppMemberSetupRoute ||
      requestedRoute is AppLoadingRoute) {
    return const GroupTimelineGroupListDestination();
  }
  return requestedRoute;
}

class AppRouterDelegate extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  AppRouterDelegate(this.ref);

  final Ref ref;

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  AppRoute get currentConfiguration => resolveAppRoute(
    ref.read(authNotifierProvider),
    ref.read(appNavigationNotifierProvider),
  );

  void refresh() {
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final route = currentConfiguration;
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage<void>(
          key: ValueKey(route.runtimeType),
          child: _buildPage(route),
        ),
      ],
      onDidRemovePage: (_) {},
    );
  }

  Widget _buildPage(AppRoute route) {
    return switch (route) {
      AppLoadingRoute() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AppLoginRoute() => const LoginPage(),
      AppSignupRoute() => const SignupPage(),
      AppMemberSetupRoute() => const AuthGuard(child: SizedBox.shrink()),
      _ => const TopPage(),
    };
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) async {
    ref.read(appNavigationNotifierProvider.notifier).go(configuration);
  }

  @override
  Future<bool> popRoute() async {
    final navigator = navigatorKey?.currentState;
    if (navigator != null && await navigator.maybePop()) {
      return true;
    }

    final route = currentConfiguration;
    if (route is AppSignupRoute) {
      ref.read(appNavigationNotifierProvider.notifier).showLogin();
      return true;
    }
    if (route is AppLoadingRoute ||
        route is AppLoginRoute ||
        route is AppMemberSetupRoute) {
      return false;
    }
    return ref.read(appNavigationNotifierProvider.notifier).goBack();
  }
}

class AppRouteInformationParser extends RouteInformationParser<AppRoute> {
  const AppRouteInformationParser();

  @override
  Future<AppRoute> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;
    if (segments.length == 1) {
      return switch (segments.single) {
        'login' => const AppLoginRoute(),
        'signup' => const AppSignupRoute(),
        'groups' => const GroupTimelineGroupListDestination(),
        'map' => const AppMapRoute(),
        'members' => const AppMemberManagementRoute(),
        'group-management' => const AppGroupManagementRoute(),
        'settings' => const AppSettingsRoute(),
        'account-settings' => const AppAccountSettingsRoute(),
        _ => const GroupTimelineGroupListDestination(),
      };
    }
    if (segments.length == 3 &&
        segments.first == 'groups' &&
        segments.last == 'timeline') {
      return GroupTimelineOverviewDestination(groupId: segments[1]);
    }
    if (segments.length == 3 &&
        segments.first == 'groups' &&
        segments.last == 'dvc') {
      return GroupTimelineDvcPointCalculationDestination(groupId: segments[1]);
    }
    if (segments.length == 4 &&
        segments.first == 'groups' &&
        segments[2] == 'trips') {
      final year = int.tryParse(segments[3]);
      if (year != null) {
        return GroupTimelineTripManagementDestination(
          groupId: segments[1],
          year: year,
          initialTripId: uri.queryParameters['tripId'],
        );
      }
    }
    return const GroupTimelineGroupListDestination();
  }

  @override
  RouteInformation restoreRouteInformation(AppRoute configuration) {
    final uri = switch (configuration) {
      AppLoadingRoute() || AppMemberSetupRoute() => Uri(path: '/login'),
      AppLoginRoute() => Uri(path: '/login'),
      AppSignupRoute() => Uri(path: '/signup'),
      GroupTimelineGroupListDestination() => Uri(path: '/groups'),
      GroupTimelineOverviewDestination(:final groupId) => Uri(
        pathSegments: ['groups', groupId, 'timeline'],
      ),
      GroupTimelineTripManagementDestination(
        :final groupId,
        :final year,
        :final initialTripId,
      ) =>
        Uri(
          pathSegments: ['groups', groupId, 'trips', '$year'],
          queryParameters: initialTripId == null
              ? null
              : {'tripId': initialTripId},
        ),
      GroupTimelineDvcPointCalculationDestination(:final groupId) => Uri(
        pathSegments: ['groups', groupId, 'dvc'],
      ),
      AppMapRoute() => Uri(path: '/map'),
      AppMemberManagementRoute() => Uri(path: '/members'),
      AppGroupManagementRoute() => Uri(path: '/group-management'),
      AppSettingsRoute() => Uri(path: '/settings'),
      AppAccountSettingsRoute() => Uri(path: '/account-settings'),
    };
    return RouteInformation(uri: uri);
  }
}
