// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $loadingRoute,
  $loginRoute,
  $signupRoute,
  $memberSetupRoute,
  $appShellRoute,
];

RouteBase get $loadingRoute => GoRouteData.$route(
  path: '/loading',
  hasOverriddenOnExit: false,
  factory: $LoadingRoute._fromState,
);

mixin $LoadingRoute on GoRouteData {
  static LoadingRoute _fromState(GoRouterState state) => const LoadingRoute();

  @override
  String get location => GoRouteData.$location('/loading');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
  path: '/login',
  hasOverriddenOnExit: false,
  factory: $LoginRoute._fromState,
);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $signupRoute => GoRouteData.$route(
  path: '/signup',
  hasOverriddenOnExit: false,
  factory: $SignupRoute._fromState,
);

mixin $SignupRoute on GoRouteData {
  static SignupRoute _fromState(GoRouterState state) => const SignupRoute();

  @override
  String get location => GoRouteData.$location('/signup');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $memberSetupRoute => GoRouteData.$route(
  path: '/member-setup',
  hasOverriddenOnExit: false,
  factory: $MemberSetupRoute._fromState,
);

mixin $MemberSetupRoute on GoRouteData {
  static MemberSetupRoute _fromState(GoRouterState state) =>
      const MemberSetupRoute();

  @override
  String get location => GoRouteData.$location('/member-setup');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRoute => ShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/groups',
      hasOverriddenOnExit: false,
      factory: $GroupListRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: ':groupId/timeline',
          hasOverriddenOnExit: false,
          factory: $GroupTimelineRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'trips/:year',
              hasOverriddenOnExit: false,
              factory: $TripManagementRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'dvc',
              hasOverriddenOnExit: false,
              factory: $DvcPointCalculationRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    GoRouteData.$route(
      path: '/map',
      hasOverriddenOnExit: false,
      factory: $MapRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/members',
      hasOverriddenOnExit: false,
      factory: $MemberManagementRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/group-management',
      hasOverriddenOnExit: false,
      factory: $GroupManagementRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/account-settings',
      hasOverriddenOnExit: false,
      factory: $AccountSettingsRoute._fromState,
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $GroupListRoute on GoRouteData {
  static GroupListRoute _fromState(GoRouterState state) =>
      const GroupListRoute();

  @override
  String get location => GoRouteData.$location('/groups');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GroupTimelineRoute on GoRouteData {
  static GroupTimelineRoute _fromState(GoRouterState state) =>
      GroupTimelineRoute(groupId: state.pathParameters['groupId']!);

  GroupTimelineRoute get _self => this as GroupTimelineRoute;

  @override
  String get location => GoRouteData.$location(
    '/groups/${Uri.encodeComponent(_self.groupId)}/timeline',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TripManagementRoute on GoRouteData {
  static TripManagementRoute _fromState(GoRouterState state) =>
      TripManagementRoute(
        groupId: state.pathParameters['groupId']!,
        year: int.parse(state.pathParameters['year']!),
        tripId: state.uri.queryParameters['trip-id'],
      );

  TripManagementRoute get _self => this as TripManagementRoute;

  @override
  String get location => GoRouteData.$location(
    '/groups/${Uri.encodeComponent(_self.groupId)}/timeline/trips/${Uri.encodeComponent(_self.year.toString())}',
    queryParams: {if (_self.tripId != null) 'trip-id': _self.tripId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DvcPointCalculationRoute on GoRouteData {
  static DvcPointCalculationRoute _fromState(GoRouterState state) =>
      DvcPointCalculationRoute(groupId: state.pathParameters['groupId']!);

  DvcPointCalculationRoute get _self => this as DvcPointCalculationRoute;

  @override
  String get location => GoRouteData.$location(
    '/groups/${Uri.encodeComponent(_self.groupId)}/timeline/dvc',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MapRoute on GoRouteData {
  static MapRoute _fromState(GoRouterState state) => const MapRoute();

  @override
  String get location => GoRouteData.$location('/map');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MemberManagementRoute on GoRouteData {
  static MemberManagementRoute _fromState(GoRouterState state) =>
      const MemberManagementRoute();

  @override
  String get location => GoRouteData.$location('/members');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GroupManagementRoute on GoRouteData {
  static GroupManagementRoute _fromState(GoRouterState state) =>
      const GroupManagementRoute();

  @override
  String get location => GoRouteData.$location('/group-management');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountSettingsRoute on GoRouteData {
  static AccountSettingsRoute _fromState(GoRouterState state) =>
      const AccountSettingsRoute();

  @override
  String get location => GoRouteData.$location('/account-settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
