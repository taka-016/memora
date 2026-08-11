import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

class AppRedirectController {
  String? _pendingProtectedLocation;
  bool _canCaptureProtectedLocation = true;

  void handleAuthStateChange(AuthState? previous, AuthState next) {
    if (_isAuthenticationSessionEnding(previous, next)) {
      _discardPendingProtectedLocation();
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
      return _consumePendingProtectedLocation();
    }
    return null;
  }

  String _consumePendingProtectedLocation() {
    final destination =
        _pendingProtectedLocation ?? const GroupListRoute().location;
    _discardPendingProtectedLocation();
    return destination;
  }

  void _discardPendingProtectedLocation() {
    _pendingProtectedLocation = null;
  }
}

bool _isAuthenticationSessionEnding(AuthState? previous, AuthState next) {
  final hadAuthenticationSession =
      previous?.isAuthenticated == true ||
      previous?.requiresMemberSelection == true;
  final keepsAuthenticationSession =
      next.isAuthenticated || next.requiresMemberSelection;
  return hadAuthenticationSession && !keepsAuthenticationSession;
}

String? _safeLocationFor(Uri uri) {
  final segments = uri.pathSegments;
  final isTripManagementLocation =
      segments.length == 5 &&
      segments[0] == 'groups' &&
      segments[2] == 'timeline' &&
      segments[3] == 'trips';
  if (!isTripManagementLocation) {
    return null;
  }
  final year = int.tryParse(segments[4]);
  if (year != null && year >= 2000 && year <= 2100) {
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
