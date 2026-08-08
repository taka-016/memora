import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/presentation/features/auth/auth_guard.dart';
import 'package:memora/presentation/features/auth/login_page.dart';
import 'package:memora/presentation/features/auth/signup_page.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

part 'app_routes.g.dart';

@TypedGoRoute<LoadingRoute>(path: '/loading')
class LoadingRoute extends GoRouteData with $LoadingRoute {
  const LoadingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginPage();
  }
}

@TypedGoRoute<SignupRoute>(path: '/signup')
class SignupRoute extends GoRouteData with $SignupRoute {
  const SignupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SignupPage();
  }
}

@TypedGoRoute<MemberSetupRoute>(path: '/member-setup')
class MemberSetupRoute extends GoRouteData with $MemberSetupRoute {
  const MemberSetupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AuthGuard(child: SizedBox.shrink());
  }
}

@TypedShellRoute<AppShellRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<GroupListRoute>(
      path: '/groups',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<GroupTimelineRoute>(
          path: ':groupId/timeline',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<TripManagementRoute>(path: 'trips/:year'),
            TypedGoRoute<DvcPointCalculationRoute>(path: 'dvc'),
          ],
        ),
      ],
    ),
    TypedGoRoute<MapRoute>(path: '/map'),
    TypedGoRoute<MemberManagementRoute>(path: '/members'),
    TypedGoRoute<GroupManagementRoute>(path: '/group-management'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
    TypedGoRoute<AccountSettingsRoute>(path: '/account-settings'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return navigator;
  }
}

class GroupListRoute extends GoRouteData with $GroupListRoute {
  const GroupListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class GroupTimelineRoute extends GoRouteData with $GroupTimelineRoute {
  const GroupTimelineRoute({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class TripManagementRoute extends GoRouteData with $TripManagementRoute {
  const TripManagementRoute({
    required this.groupId,
    required this.year,
    @TypedQueryParameter(name: 'trip-id') this.tripId,
  });

  final String groupId;
  final int year;
  final String? tripId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class DvcPointCalculationRoute extends GoRouteData
    with $DvcPointCalculationRoute {
  const DvcPointCalculationRoute({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class MapRoute extends GoRouteData with $MapRoute {
  const MapRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class MemberManagementRoute extends GoRouteData with $MemberManagementRoute {
  const MemberManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class GroupManagementRoute extends GoRouteData with $GroupManagementRoute {
  const GroupManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

class AccountSettingsRoute extends GoRouteData with $AccountSettingsRoute {
  const AccountSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}

String? resolveAppRedirect({
  required AuthState authState,
  required String matchedLocation,
}) {
  final signupLocation = const SignupRoute().location;
  final loadingLocation = const LoadingRoute().location;
  final loginLocation = const LoginRoute().location;
  final memberSetupLocation = const MemberSetupRoute().location;
  final groupListLocation = const GroupListRoute().location;

  if (authState.isLoading) {
    if (matchedLocation == signupLocation ||
        matchedLocation == loadingLocation) {
      return null;
    }
    return loadingLocation;
  }
  if (authState.requiresMemberSelection) {
    return matchedLocation == memberSetupLocation ? null : memberSetupLocation;
  }
  if (!authState.isAuthenticated) {
    if (matchedLocation == loginLocation || matchedLocation == signupLocation) {
      return null;
    }
    return loginLocation;
  }
  if (matchedLocation == loadingLocation ||
      matchedLocation == loginLocation ||
      matchedLocation == signupLocation ||
      matchedLocation == memberSetupLocation) {
    return groupListLocation;
  }
  return null;
}
