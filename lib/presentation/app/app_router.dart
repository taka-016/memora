import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

final appRouterConfigProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AuthState>(authNotifierProvider, (_, _) {
    refreshNotifier.refresh();
  });

  final platformLocation = Uri.tryParse(
    WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );
  final initialLocation =
      platformLocation == null ||
          platformLocation.path.isEmpty ||
          platformLocation.path == '/'
      ? const GroupListRoute().location
      : platformLocation.toString();
  final router = GoRouter(
    routes: appRoutes,
    initialLocation: initialLocation,
    refreshListenable: refreshNotifier,
    redirect: (_, state) {
      return resolveAppRedirect(
        authState: ref.read(authNotifierProvider),
        matchedLocation: state.matchedLocation,
      );
    },
  );
  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
