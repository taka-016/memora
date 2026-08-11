import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/app/app_routes.dart';

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
}
