import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/app/app_redirect_controller.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/features/auth/signup_page.dart';
import 'package:memora/presentation/notifiers/android_widget_launch_notifier.dart';
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

  void unauthenticate() {
    state = const AuthState.unauthenticated('');
  }

  void startLogout() {
    state = const AuthState.loading();
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

class _TrackingAndroidWidgetLaunchNotifier extends AndroidWidgetLaunchNotifier {
  _TrackingAndroidWidgetLaunchNotifier({
    this.initialState = const AndroidWidgetLaunchState(
      isInitialUriLoading: true,
    ),
  });

  final AndroidWidgetLaunchState initialState;
  var cancelCount = 0;

  @override
  AndroidWidgetLaunchState build() {
    return initialState;
  }

  @override
  void cancelPendingLaunch() {
    cancelCount++;
    super.cancelPendingLaunch();
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
    GroupTimelineGroupSelectionNotifier? groupSelectionNotifier,
    AndroidWidgetLaunchNotifier? androidWidgetLaunchNotifier,
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
            () => groupSelectionNotifier ?? _LoadedGroupSelectionNotifier(),
          ),
          androidWidgetLaunchNotifierProvider.overrideWith(
            () =>
                androidWidgetLaunchNotifier ??
                _TrackingAndroidWidgetLaunchNotifier(),
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

  testWidgets('ログアウトのloading状態では前セッションの保護ルートを保持しない', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final (_, router) = await pumpRouter(tester, authNotifier);
    router.go(const SettingsRoute().location);
    await pumpNavigation(tester);

    authNotifier.startLogout();
    await pumpNavigation(tester);
    expect(router.state.uri.toString(), const LoadingRoute().location);

    authNotifier.unauthenticate();
    await pumpNavigation(tester);
    expect(router.state.uri.toString(), const LoginRoute().location);

    authNotifier.authenticate('user-2');
    await pumpNavigation(tester);
    expect(router.state.matchedLocation, const GroupListRoute().location);
  });

  testWidgets('認証済みから直接未認証になった場合は前セッションの保護ルートを保持しない', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final (_, router) = await pumpRouter(tester, authNotifier);
    router.go(const SettingsRoute().location);
    await pumpNavigation(tester);

    authNotifier.unauthenticate();
    await pumpNavigation(tester);
    expect(router.state.uri.toString(), const LoginRoute().location);

    authNotifier.authenticate('user-2');
    await pumpNavigation(tester);
    expect(router.state.matchedLocation, const GroupListRoute().location);
  });

  testWidgets('ログアウト時はグループ選択状態を破棄する', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final groupSelectionNotifier = _LoadedGroupSelectionNotifier();
    final (container, router) = await pumpRouter(
      tester,
      authNotifier,
      groupSelectionNotifier: groupSelectionNotifier,
    );

    authNotifier.unauthenticate();
    await pumpNavigation(tester);
    expect(router.state.matchedLocation, const LoginRoute().location);
    expect(
      container.read(groupTimelineGroupSelectionNotifierProvider).memberId,
      isNull,
    );
  });

  testWidgets('ログアウト時はAndroidウィジェットの起動要求を破棄する', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final androidWidgetLaunchNotifier = _TrackingAndroidWidgetLaunchNotifier(
      initialState: const AndroidWidgetLaunchState(isResolving: true),
    );
    final (container, router) = await pumpRouter(
      tester,
      authNotifier,
      androidWidgetLaunchNotifier: androidWidgetLaunchNotifier,
    );

    authNotifier.unauthenticate();
    await pumpNavigation(tester);

    expect(router.state.matchedLocation, const LoginRoute().location);
    expect(androidWidgetLaunchNotifier.cancelCount, 1);
    expect(
      container.read(androidWidgetLaunchNotifierProvider),
      const AndroidWidgetLaunchState(),
    );
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

  testWidgets('未認証確定後にログインしても保護ルートのディープリンクを復元する', (tester) async {
    final authNotifier = _MutableAuthNotifier(const AuthState.loading());
    const initialRoute = SettingsRoute();
    final (_, router) = await pumpRouter(
      tester,
      authNotifier,
      initialLocation: initialRoute.location,
    );

    authNotifier.unauthenticate();
    await pumpNavigation(tester);
    expect(router.state.matchedLocation, const LoginRoute().location);

    authNotifier.authenticate('user-1');
    await pumpNavigation(tester);

    expect(router.state.uri.toString(), initialRoute.location);
  });

  test('認証画面とメンバー作成画面を経由してもディープリンクを復元する', () {
    final controller = AppRedirectController();
    const initialRoute = SettingsRoute();
    const loading = AuthState.loading();
    const unauthenticated = AuthState.unauthenticated('');
    const memberSelection = AuthState.unauthenticated(
      memberSelectionRequiredMessage,
    );
    const authenticated = AuthState.authenticated(
      UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
    );

    expect(
      controller.resolve(
        authState: loading,
        matchedLocation: initialRoute.location,
        location: initialRoute.location,
      ),
      const LoadingRoute().location,
    );
    controller.handleAuthStateChange(loading, unauthenticated);
    expect(
      controller.resolve(
        authState: unauthenticated,
        matchedLocation: const LoadingRoute().location,
        location: const LoadingRoute().location,
      ),
      const LoginRoute().location,
    );
    expect(
      controller.resolve(
        authState: unauthenticated,
        matchedLocation: const SignupRoute().location,
        location: const SignupRoute().location,
      ),
      isNull,
    );
    controller.handleAuthStateChange(unauthenticated, memberSelection);
    expect(
      controller.resolve(
        authState: memberSelection,
        matchedLocation: const SignupRoute().location,
        location: const SignupRoute().location,
      ),
      const MemberSetupRoute().location,
    );
    expect(
      controller.resolve(
        authState: memberSelection,
        matchedLocation: const MemberSetupRoute().location,
        location: const MemberSetupRoute().location,
      ),
      isNull,
    );
    controller.handleAuthStateChange(memberSelection, authenticated);
    expect(
      controller.resolve(
        authState: authenticated,
        matchedLocation: const MemberSetupRoute().location,
        location: const MemberSetupRoute().location,
      ),
      initialRoute.location,
    );
  });

  test('メンバー作成を中断してログアウトするとディープリンクを破棄する', () {
    final controller = AppRedirectController();
    const initialRoute = SettingsRoute();
    const loading = AuthState.loading();
    const unauthenticated = AuthState.unauthenticated('');
    const memberSelection = AuthState.unauthenticated(
      memberSelectionRequiredMessage,
    );
    const authenticated = AuthState.authenticated(
      UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
    );

    controller.resolve(
      authState: loading,
      matchedLocation: initialRoute.location,
      location: initialRoute.location,
    );
    controller.handleAuthStateChange(loading, memberSelection);
    controller.resolve(
      authState: memberSelection,
      matchedLocation: const LoadingRoute().location,
      location: const LoadingRoute().location,
    );

    controller.handleAuthStateChange(memberSelection, loading);
    controller.resolve(
      authState: loading,
      matchedLocation: const MemberSetupRoute().location,
      location: const MemberSetupRoute().location,
    );
    controller.handleAuthStateChange(loading, unauthenticated);
    controller.resolve(
      authState: unauthenticated,
      matchedLocation: const LoadingRoute().location,
      location: const LoadingRoute().location,
    );
    controller.handleAuthStateChange(unauthenticated, authenticated);

    expect(
      controller.resolve(
        authState: authenticated,
        matchedLocation: const LoginRoute().location,
        location: const LoginRoute().location,
      ),
      const GroupListRoute().location,
    );
  });

  testWidgets('旅行管理ルートの年が整数でない場合はグループ年表へ戻る', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final (_, router) = await pumpRouter(
      tester,
      authNotifier,
      initialLocation: '/groups/deep-link-group/timeline/trips/not-a-year',
    );

    expect(tester.takeException(), isNull);
    expect(
      router.state.uri.toString(),
      const GroupTimelineRoute(groupId: 'deep-link-group').location,
    );
  });

  for (final invalidYear in [1999, 2101, 999999999]) {
    testWidgets('旅行管理ルートの年が$invalidYearの場合はグループ年表へ戻る', (tester) async {
      final authNotifier = _MutableAuthNotifier(
        const AuthState.authenticated(
          UserDto(
            id: 'user-1',
            loginId: 'user-1@example.com',
            isVerified: true,
          ),
        ),
      );
      final (_, router) = await pumpRouter(
        tester,
        authNotifier,
        initialLocation: '/groups/deep-link-group/timeline/trips/$invalidYear',
      );

      expect(tester.takeException(), isNull);
      expect(
        router.state.uri.toString(),
        const GroupTimelineRoute(groupId: 'deep-link-group').location,
      );
    });
  }

  testWidgets('起動済みアプリへ届いたウィジェットURIはグループ一覧へ退避する', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final (_, router) = await pumpRouter(
      tester,
      authNotifier,
      initialLocation: 'memorawidget://opentrip/?tripId=trip-1',
    );

    expect(tester.takeException(), isNull);
    expect(router.state.uri.toString(), const GroupListRoute().location);
  });

  testWidgets('ルートパスはグループ一覧へ退避する', (tester) async {
    final authNotifier = _MutableAuthNotifier(
      const AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'user-1@example.com', isVerified: true),
      ),
    );
    final (_, router) = await pumpRouter(
      tester,
      authNotifier,
      initialLocation: '/',
    );

    expect(tester.takeException(), isNull);
    expect(router.state.uri.toString(), const GroupListRoute().location);
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
