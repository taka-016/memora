import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/features/auth/signup_page.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

import '../../../helpers/fake_auth_notifier.dart';

class _MutableAuthNotifier extends FakeAuthNotifier {
  _MutableAuthNotifier(super.initialState);

  void authenticate(String userId) {
    state = AuthState.authenticated(
      UserDto(id: userId, loginId: '$userId@example.com', isVerified: true),
    );
  }
}

void main() {
  Future<(ProviderContainer, GoRouter)> pumpRouter(
    WidgetTester tester,
    FakeAuthNotifier authNotifier,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => authNotifier)],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              routerConfig: ref.watch(appRouterConfigProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    return (container, container.read(appRouterConfigProvider));
  }

  testWidgets('詳細画面から年表、グループ一覧の順に戻る', (tester) async {
    final (_, router) = await pumpRouter(
      tester,
      FakeAuthNotifier.authenticated(),
    );
    const timelineRoute = GroupTimelineRoute(groupId: 'group-1');
    const tripRoute = TripManagementRoute(
      groupId: 'group-1',
      year: 2026,
      tripId: 'trip-1',
    );

    router.go(tripRoute.location);
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, tripRoute.location.split('?').first);

    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, timelineRoute.location);

    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, const GroupListRoute().location);
  });

  testWidgets('Drawer画面から戻ると遷移前の年表へ戻る', (tester) async {
    final (_, router) = await pumpRouter(
      tester,
      FakeAuthNotifier.authenticated(),
    );
    const timelineRoute = GroupTimelineRoute(groupId: 'group-1');

    router.go(timelineRoute.location);
    await tester.pumpAndSettle();
    router.push(const SettingsRoute().location);
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, const SettingsRoute().location);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, timelineRoute.location);
  });

  testWidgets('ログアウト後の再認証では前セッションの保護ルートを破棄する', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final (_, router) = await pumpRouter(tester, authNotifier);
    router.go(
      const GroupTimelineRoute(groupId: 'previous-session-group').location,
    );
    await tester.pumpAndSettle();

    await authNotifier.logout();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, const LoginRoute().location);

    authNotifier.authenticate('user-2');
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, const GroupListRoute().location);
  });

  testWidgets('戻る操作では画面ルートより先にダイアログを閉じる', (tester) async {
    final (_, router) = await pumpRouter(
      tester,
      FakeAuthNotifier.unauthenticated(),
    );
    router.go(const SignupRoute().location);
    await tester.pumpAndSettle();

    showDialog<void>(
      context: tester.element(find.byType(SignupPage)),
      builder: (_) => const AlertDialog(content: Text('確認ダイアログ')),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('確認ダイアログ'), findsNothing);
    expect(router.state.matchedLocation, const SignupRoute().location);
  });
}
