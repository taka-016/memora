import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/app/app_route.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/notifiers/app_navigation_notifier.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

void main() {
  group('AppRouteInformationParser', () {
    const parser = AppRouteInformationParser();
    const routes = <AppRoute>[
      AppLoginRoute(),
      AppSignupRoute(),
      GroupTimelineGroupListDestination(),
      GroupTimelineOverviewDestination(groupId: 'group 1'),
      GroupTimelineTripManagementDestination(
        groupId: 'group 1',
        year: 2026,
        initialTripId: 'trip 1',
      ),
      GroupTimelineDvcPointCalculationDestination(groupId: 'group 1'),
      AppMapRoute(),
      AppMemberManagementRoute(),
      AppGroupManagementRoute(),
      AppSettingsRoute(),
      AppAccountSettingsRoute(),
    ];

    for (final route in routes) {
      test('$route をURLから復元できる', () async {
        final information = parser.restoreRouteInformation(route);
        final restored = await parser.parseRouteInformation(information);

        expect(restored, route);
      });
    }
  });

  group('resolveAppRoute', () {
    test('未認証で保護対象へ遷移するとログインへリダイレクトする', () {
      expect(
        resolveAppRoute(
          const AuthState.unauthenticated(''),
          const AppMapRoute(),
        ),
        const AppLoginRoute(),
      );
    });

    test('未認証では新規登録ルートを維持する', () {
      expect(
        resolveAppRoute(
          const AuthState.unauthenticated(''),
          const AppSignupRoute(),
        ),
        const AppSignupRoute(),
      );
    });

    test('メンバー未作成ではログインと別の選択導線へリダイレクトする', () {
      expect(
        resolveAppRoute(
          const AuthState.unauthenticated(memberSelectionRequiredMessage),
          const GroupTimelineGroupListDestination(),
        ),
        const AppMemberSetupRoute(),
      );
    });

    test('認証済みで認証画面を指定するとグループ選択へリダイレクトする', () {
      expect(
        resolveAppRoute(
          const AuthState.authenticated(
            UserDto(
              id: 'user-1',
              loginId: 'test@example.com',
              isVerified: true,
            ),
          ),
          const AppLoginRoute(),
        ),
        const GroupTimelineGroupListDestination(),
      );
    });
  });

  group('AppNavigationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('詳細画面から年表、グループ選択の順に戻る', () {
      final notifier = container.read(appNavigationNotifierProvider.notifier);
      notifier.showTripManagement(
        groupId: 'group-1',
        year: 2026,
        initialTripId: 'trip-1',
      );

      expect(notifier.goBack(), isTrue);
      expect(
        container.read(appNavigationNotifierProvider),
        const GroupTimelineOverviewDestination(groupId: 'group-1'),
      );

      expect(notifier.goBack(), isTrue);
      expect(
        container.read(appNavigationNotifierProvider),
        const GroupTimelineGroupListDestination(),
      );
      expect(notifier.goBack(), isFalse);
    });

    test('Drawer画面から戻るとグループ選択へ遷移する', () {
      final notifier = container.read(appNavigationNotifierProvider.notifier);
      notifier.go(const AppSettingsRoute());

      expect(notifier.goBack(), isTrue);
      expect(
        container.read(appNavigationNotifierProvider),
        const GroupTimelineGroupListDestination(),
      );
    });

    test('ウィジェットとアプリ内操作で同じ旅行管理ルートを使用する', () {
      final notifier = container.read(appNavigationNotifierProvider.notifier);

      notifier.showTripManagement(
        groupId: 'group-1',
        year: 2026,
        initialTripId: 'trip-1',
      );

      expect(
        container.read(appNavigationNotifierProvider),
        const GroupTimelineTripManagementDestination(
          groupId: 'group-1',
          year: 2026,
          initialTripId: 'trip-1',
        ),
      );
    });
  });
}
