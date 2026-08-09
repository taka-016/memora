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
  var preserveProtectedRedirect = true;
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    preserveProtectedRedirect = !_isLogoutStarting(previous, next);
    refreshNotifier.refresh();
  });

  final router = GoRouter(
    routes: appRoutes,
    initialLocation: ref.watch(appInitialLocationProvider),
    refreshListenable: refreshNotifier,
    redirect: (_, state) {
      return resolveAppRedirect(
        authState: ref.read(authNotifierProvider),
        matchedLocation: state.matchedLocation,
        location: state.uri.toString(),
        preserveProtectedRedirect: preserveProtectedRedirect,
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
  return previous?.isAuthenticated == true && next.isLoading;
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
