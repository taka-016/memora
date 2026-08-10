import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

final appInitialLocationProvider = Provider<String>((ref) {
  final platformLocation = Uri.tryParse(
    WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );
  return platformLocation == null ||
          platformLocation.path.isEmpty ||
          platformLocation.path == '/'
      ? const GroupListRoute().location
      : platformLocation.toString();
});

final appRouterConfigProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  final redirectController = AppRedirectController();
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    redirectController.handleAuthStateChange(previous, next);
    refreshNotifier.refresh();
  });

  final router = GoRouter(
    routes: appRoutes,
    initialLocation: ref.watch(appInitialLocationProvider),
    refreshListenable: refreshNotifier,
    redirect: (_, state) {
      return redirectController.resolve(
        authState: ref.read(authNotifierProvider),
        matchedLocation: state.matchedLocation,
        location: state.uri.toString(),
      );
    },
  );
  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
});

bool _isLogoutStarting(AuthState? previous, AuthState next) {
  return (previous?.isAuthenticated == true ||
          previous?.requiresMemberSelection == true) &&
      next.isLoading;
}

class AppRedirectController {
  String? _pendingProtectedLocation;
  bool _canCaptureProtectedLocation = true;

  void handleAuthStateChange(AuthState? previous, AuthState next) {
    if (_isLogoutStarting(previous, next)) {
      _pendingProtectedLocation = null;
      _canCaptureProtectedLocation = false;
      return;
    }
    if (!next.isLoading) {
      _canCaptureProtectedLocation = true;
    }
  }

  String? resolve({
    required AuthState authState,
    required String matchedLocation,
    required String location,
  }) {
    final currentUri = Uri.parse(location);
    final safeLocation = _safeLocationFor(currentUri);
    if (safeLocation != null) {
      return safeLocation;
    }
    final loadingLocation = const LoadingRoute().location;
    final loginLocation = const LoginRoute().location;
    final signupLocation = const SignupRoute().location;
    final memberSetupLocation = const MemberSetupRoute().location;
    final groupListLocation = const GroupListRoute().location;

    if (_canCaptureProtectedLocation &&
        !authState.isAuthenticated &&
        _isProtectedLocation(currentUri.path)) {
      _pendingProtectedLocation = currentUri.toString();
    }

    if (authState.isLoading) {
      if (matchedLocation == signupLocation ||
          matchedLocation == loadingLocation) {
        return null;
      }
      return loadingLocation;
    }
    if (authState.requiresMemberSelection) {
      return matchedLocation == memberSetupLocation
          ? null
          : memberSetupLocation;
    }
    if (!authState.isAuthenticated) {
      if (matchedLocation == loginLocation ||
          matchedLocation == signupLocation) {
        return null;
      }
      return loginLocation;
    }
    if (_isAuthenticationLocation(matchedLocation)) {
      final destination = _pendingProtectedLocation ?? groupListLocation;
      _pendingProtectedLocation = null;
      return destination;
    }
    return null;
  }
}

String? _safeLocationFor(Uri uri) {
  final segments = uri.pathSegments;
  final isTripManagementLocation =
      segments.length == 5 &&
      segments[0] == 'groups' &&
      segments[2] == 'timeline' &&
      segments[3] == 'trips';
  if (!isTripManagementLocation || int.tryParse(segments[4]) != null) {
    return null;
  }
  return GroupTimelineRoute(groupId: segments[1]).location;
}

bool _isAuthenticationLocation(String location) {
  return location == const LoadingRoute().location ||
      location == const LoginRoute().location ||
      location == const SignupRoute().location ||
      location == const MemberSetupRoute().location;
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

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
