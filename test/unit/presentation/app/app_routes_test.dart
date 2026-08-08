import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/auth_state.dart';

void main() {
  group('型付きルート', () {
    test('画面パラメータからURLを生成する', () {
      expect(const LoginRoute().location, '/login');
      expect(const SignupRoute().location, '/signup');
      expect(const GroupListRoute().location, '/groups');
      expect(
        const GroupTimelineRoute(groupId: 'group 1').location,
        '/groups/group%201/timeline',
      );
      expect(
        const TripManagementRoute(
          groupId: 'group 1',
          year: 2026,
          tripId: 'trip 1',
        ).location,
        '/groups/group%201/timeline/trips/2026?trip-id=trip+1',
      );
      expect(
        const DvcPointCalculationRoute(groupId: 'group 1').location,
        '/groups/group%201/timeline/dvc',
      );
      expect(const MapRoute().location, '/map');
      expect(const MemberManagementRoute().location, '/members');
      expect(const GroupManagementRoute().location, '/group-management');
      expect(const SettingsRoute().location, '/settings');
      expect(const AccountSettingsRoute().location, '/account-settings');
    });

    test('現在地からDrawerの選択項目を決定する', () {
      expect(
        appNavigationItemForLocation(const GroupListRoute().location),
        AppNavigationItem.groupTimeline,
      );
      expect(
        appNavigationItemForLocation(
          const TripManagementRoute(groupId: 'group-1', year: 2026).location,
        ),
        AppNavigationItem.groupTimeline,
      );
      expect(
        appNavigationItemForLocation(const MapRoute().location),
        AppNavigationItem.map,
      );
      expect(
        appNavigationItemForLocation(const MemberManagementRoute().location),
        AppNavigationItem.memberManagement,
      );
      expect(
        appNavigationItemForLocation(const GroupManagementRoute().location),
        AppNavigationItem.groupManagement,
      );
      expect(
        appNavigationItemForLocation(const SettingsRoute().location),
        AppNavigationItem.settings,
      );
      expect(
        appNavigationItemForLocation(const AccountSettingsRoute().location),
        AppNavigationItem.accountSettings,
      );
    });
  });

  group('resolveAppRedirect', () {
    test('登録処理中は新規登録画面を維持する', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState.loading(),
          matchedLocation: const SignupRoute().location,
        ),
        isNull,
      );
    });

    test('初期認証中は保護ルートを保持してローディング画面へ遷移する', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState.loading(),
          matchedLocation: const GroupListRoute().location,
        ),
        const LoadingRoute(redirectLocation: '/groups').location,
      );
    });

    test('未認証で保護画面を指定するとログイン画面へ遷移する', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState.unauthenticated(''),
          matchedLocation: const MapRoute().location,
        ),
        const LoginRoute().location,
      );
    });

    test('メンバー未作成ではメンバー作成選択画面へ遷移する', () {
      expect(
        resolveAppRedirect(
          authState: const AuthState.unauthenticated(
            memberSelectionRequiredMessage,
          ),
          matchedLocation: const GroupListRoute().location,
        ),
        const MemberSetupRoute().location,
      );
    });

    test('認証済みで認証画面にいる場合はグループ一覧へ遷移する', () {
      const authenticated = AuthState.authenticated(
        UserDto(id: 'user-1', loginId: 'test@example.com', isVerified: true),
      );

      expect(
        resolveAppRedirect(
          authState: authenticated,
          matchedLocation: const LoginRoute().location,
        ),
        const GroupListRoute().location,
      );
      expect(
        resolveAppRedirect(
          authState: authenticated,
          matchedLocation: const SignupRoute().location,
        ),
        const GroupListRoute().location,
      );
    });
  });
}
