import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/main.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

import '../../../helpers/fake_current_member_notifier.dart';
import '../../../helpers/test_exception.dart';

class _IdleLaunch extends AndroidWidgetLaunchNotifier {
  @override
  AndroidWidgetLaunchState build() => const AndroidWidgetLaunchState();
}

class _LoadedGroups extends GroupTimelineGroupSelectionNotifier {
  @override
  GroupTimelineGroupSelectionState build() =>
      const GroupTimelineGroupSelectionState(
        status: GroupTimelineGroupSelectionStatus.loaded,
        memberId: 'local-member',
      );
}

void main() {
  for (final path in [
    '/groups',
    '/login',
    '/signup',
    '/member-setup',
    '/account-settings',
  ]) {
    testWidgets('オフラインでは$pathから認証を解決せず年表へ起動する', (tester) async {
      var authResolutions = 0;
      final container = ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(AppMode.offline),
          appInitialLocationProvider.overrideWithValue(path),
          authServiceProvider.overrideWith((ref) {
            authResolutions++;
            throw TestException('認証は利用しない');
          }),
          currentMemberNotifierProvider.overrideWith(
            () => FakeCurrentMemberNotifier.loaded(
              const MemberDto(id: 'local-member', displayName: '本人'),
            ),
          ),
          groupTimelineGroupSelectionNotifierProvider.overrideWith(
            _LoadedGroups.new,
          ),
          androidWidgetLaunchNotifierProvider.overrideWith(_IdleLaunch.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(appRouterConfigProvider).state.uri.path, '/groups');
      expect(authResolutions, 0);
      await tester.tap(find.byKey(const Key('hamburger_menu')));
      await tester.pumpAndSettle();
      expect(find.text('ログアウト'), findsNothing);
      expect(find.text('アカウント設定'), findsNothing);
      expect(find.text('地図表示'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
