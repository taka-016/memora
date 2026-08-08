import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/features/auth/signup_page.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';

import '../../../helpers/fake_auth_notifier.dart';
import '../../../helpers/fake_current_member_notifier.dart';

class _MutableAuthNotifier extends FakeAuthNotifier {
  _MutableAuthNotifier(super.initialState);

  void authenticate(String userId) {
    state = AuthState.authenticated(
      UserDto(id: userId, loginId: '$userId@example.com', isVerified: true),
    );
  }
}

class _LoadedGroupSelectionNotifier
    extends GroupTimelineGroupSelectionNotifier {
  @override
  GroupTimelineGroupSelectionState build() {
    return const GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loaded,
      memberId: 'router-test-member',
    );
  }
}

void main() {
  Future<void> pumpNavigation(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<(ProviderContainer, GoRouter)> pumpRouter(
    WidgetTester tester,
    FakeAuthNotifier authNotifier, {
    String initialLocation = '/groups',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => authNotifier),
          currentMemberNotifierProvider.overrideWith(
            () => FakeCurrentMemberNotifier.loaded(
              const MemberDto(
                id: 'router-test-member',
                displayName: 'Routerテスト',
              ),
            ),
          ),
          groupTimelineGroupSelectionNotifierProvider.overrideWith(
            _LoadedGroupSelectionNotifier.new,
          ),
          appInitialLocationProvider.overrideWithValue(initialLocation),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              routerConfig: ref.watch(appRouterConfigProvider),
            );
          },
        ),
      ),
    );
    await pumpNavigation(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    return (container, container.read(appRouterConfigProvider));
  }

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
    await pumpNavigation(tester);

    await authNotifier.logout();
    await pumpNavigation(tester);
    expect(router.state.matchedLocation, const LoginRoute().location);

    authNotifier.authenticate('user-2');
    await pumpNavigation(tester);
    expect(router.state.matchedLocation, const GroupListRoute().location);
  });

  testWidgets('初期認証の完了後に保護ルートのディープリンクを復元する', (tester) async {
    final authNotifier = _MutableAuthNotifier(const AuthState.loading());
    const initialRoute = TripManagementRoute(
      groupId: 'deep-link-group',
      year: 2026,
      tripId: 'deep-link-trip',
    );
    final (_, router) = await pumpRouter(
      tester,
      authNotifier,
      initialLocation: initialRoute.location,
    );

    authNotifier.authenticate('user-1');
    await pumpNavigation(tester);

    expect(router.state.uri.toString(), initialRoute.location);
  });

  testWidgets('戻る操作では画面ルートより先にダイアログを閉じる', (tester) async {
    final (_, router) = await pumpRouter(
      tester,
      FakeAuthNotifier.unauthenticated(),
    );
    router.go(const SignupRoute().location);
    await pumpNavigation(tester);

    showDialog<void>(
      context: tester.element(find.byType(SignupPage)),
      builder: (_) => const AlertDialog(content: Text('確認ダイアログ')),
    );
    await pumpNavigation(tester);

    await tester.binding.handlePopRoute();
    await pumpNavigation(tester);

    expect(find.text('確認ダイアログ'), findsNothing);
    expect(router.state.matchedLocation, const SignupRoute().location);
  });
}
