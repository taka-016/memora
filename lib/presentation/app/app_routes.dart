import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/features/auth/auth_guard.dart';
import 'package:memora/presentation/features/auth/login_page.dart';
import 'package:memora/presentation/features/auth/signup_page.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_screen.dart';
import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/features/timeline/group_timeline_navigation_view.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';

part 'app_routes.g.dart';

List<RouteBase> get appRoutes => $appRoutes;

final appTestEnvironmentProvider = Provider<bool>((ref) => false);

enum AppNavigationItem {
  groupTimeline,
  map,
  memberManagement,
  groupManagement,
  settings,
  accountSettings,
}

AppNavigationItem appNavigationItemForLocation(String location) {
  if (location == const MapRoute().location) {
    return AppNavigationItem.map;
  }
  if (location == const MemberManagementRoute().location) {
    return AppNavigationItem.memberManagement;
  }
  if (location == const GroupManagementRoute().location) {
    return AppNavigationItem.groupManagement;
  }
  if (location == const SettingsRoute().location) {
    return AppNavigationItem.settings;
  }
  if (location == const AccountSettingsRoute().location) {
    return AppNavigationItem.accountSettings;
  }
  return AppNavigationItem.groupTimeline;
}

@TypedGoRoute<LoadingRoute>(path: '/loading')
class LoadingRoute extends GoRouteData with $LoadingRoute {
  const LoadingRoute({
    @TypedQueryParameter(name: 'redirect') this.redirectLocation,
  });

  final String? redirectLocation;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage<void>(
      child: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute({
    @TypedQueryParameter(name: 'redirect') this.redirectLocation,
  });

  final String? redirectLocation;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage<void>(child: LoginPage());
  }
}

@TypedGoRoute<SignupRoute>(path: '/signup')
class SignupRoute extends GoRouteData with $SignupRoute {
  const SignupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage<void>(child: SignupPage());
  }
}

@TypedGoRoute<MemberSetupRoute>(path: '/member-setup')
class MemberSetupRoute extends GoRouteData with $MemberSetupRoute {
  const MemberSetupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage<void>(
      child: AuthGuard(child: SizedBox.shrink()),
    );
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
    return TopPage(
      selectedItem: appNavigationItemForLocation(state.uri.path),
      child: navigator,
    );
  }
}

class GroupListRoute extends GoRouteData with $GroupListRoute {
  const GroupListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const _GroupTimelineRoutePage();
  }
}

class GroupTimelineRoute extends GoRouteData with $GroupTimelineRoute {
  const GroupTimelineRoute({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return _GroupTimelineRoutePage(groupId: groupId);
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
    return _GroupRouteGuard(
      groupId: groupId,
      builder: (context) => Material(
        child: TripManagement(
          groupId: groupId,
          year: year,
          initialTripId: tripId,
          onBackPressed: context.pop,
        ),
      ),
    );
  }
}

class DvcPointCalculationRoute extends GoRouteData
    with $DvcPointCalculationRoute {
  const DvcPointCalculationRoute({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return _GroupRouteGuard(
      groupId: groupId,
      builder: (context) => Material(
        child: DvcPointCalculationScreen(
          groupId: groupId,
          onBackPressed: context.pop,
        ),
      ),
    );
  }
}

class MapRoute extends GoRouteData with $MapRoute {
  const MapRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return Consumer(
      builder: (context, ref, _) {
        return Material(
          child: MapScreen(
            isTestEnvironment: ref.watch(appTestEnvironmentProvider),
          ),
        );
      },
    );
  }
}

class MemberManagementRoute extends GoRouteData with $MemberManagementRoute {
  const MemberManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: MemberManagement());
  }
}

class GroupManagementRoute extends GoRouteData with $GroupManagementRoute {
  const GroupManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: GroupManagement());
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: Settings());
  }
}

class AccountSettingsRoute extends GoRouteData with $AccountSettingsRoute {
  const AccountSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: AccountSettings());
  }
}

class _GroupTimelineRoutePage extends ConsumerWidget {
  const _GroupTimelineRoutePage({this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Material(
      child: GroupTimelineNavigationView(
        currentMember: currentMember,
        groupId: groupId,
      ),
    );
  }
}

class _GroupRouteGuard extends ConsumerWidget {
  const _GroupRouteGuard({required this.groupId, required this.builder});

  final String groupId;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    final groupSelectionState = ref.watch(
      groupTimelineGroupSelectionNotifierProvider,
    );
    final canAccessGroup = _hasVerifiedGroupAccess(
      currentMemberId: currentMember?.id,
      groupId: groupId,
      groupSelectionState: groupSelectionState,
    );
    if (!canAccessGroup) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    return builder(context);
  }
}

bool _hasVerifiedGroupAccess({
  required String? currentMemberId,
  required String groupId,
  required GroupTimelineGroupSelectionState groupSelectionState,
}) {
  return currentMemberId != null &&
      groupSelectionState.status == GroupTimelineGroupSelectionStatus.loaded &&
      groupSelectionState.memberId == currentMemberId &&
      groupSelectionState.groups.any((group) => group.id == groupId);
}

String? resolveAppRedirect({
  required AuthState authState,
  required String matchedLocation,
  String? location,
}) {
  final currentUri = Uri.parse(location ?? matchedLocation);
  final signupLocation = const SignupRoute().location;
  final loadingLocation = const LoadingRoute().location;
  final loginLocation = const LoginRoute().location;
  final memberSetupLocation = const MemberSetupRoute().location;
  final groupListLocation = const GroupListRoute().location;
  final protectedRedirectLocation = _protectedRedirectLocation(currentUri);

  if (authState.isLoading) {
    if (matchedLocation == signupLocation ||
        matchedLocation == loadingLocation) {
      return null;
    }
    if (_isProtectedLocation(currentUri.path)) {
      return LoadingRoute(redirectLocation: currentUri.toString()).location;
    }
    return LoadingRoute(redirectLocation: protectedRedirectLocation).location;
  }
  if (authState.requiresMemberSelection) {
    return matchedLocation == memberSetupLocation ? null : memberSetupLocation;
  }
  if (!authState.isAuthenticated) {
    if (matchedLocation == loginLocation || matchedLocation == signupLocation) {
      return null;
    }
    return LoginRoute(redirectLocation: protectedRedirectLocation).location;
  }
  if ((matchedLocation == loadingLocation ||
          matchedLocation == loginLocation) &&
      protectedRedirectLocation != null) {
    return protectedRedirectLocation;
  }
  if (matchedLocation == loadingLocation ||
      matchedLocation == loginLocation ||
      matchedLocation == signupLocation ||
      matchedLocation == memberSetupLocation) {
    return groupListLocation;
  }
  return null;
}

String? _protectedRedirectLocation(Uri currentUri) {
  final redirectLocation = currentUri.queryParameters['redirect'];
  final redirectUri = redirectLocation == null
      ? null
      : Uri.tryParse(redirectLocation);
  return redirectUri != null && _isProtectedLocation(redirectUri.path)
      ? redirectLocation
      : null;
}

bool _isProtectedLocation(String path) {
  return path == const GroupListRoute().location ||
      path.startsWith('${const GroupListRoute().location}/') ||
      path == const MapRoute().location ||
      path == const MemberManagementRoute().location ||
      path == const GroupManagementRoute().location ||
      path == const SettingsRoute().location ||
      path == const AccountSettingsRoute().location;
}
