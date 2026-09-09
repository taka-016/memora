import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_startup_test.mocks.dart';

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
  _IdleLaunch({this.settings = false});
  final bool settings;
  @override
  AndroidWidgetLaunchState build() =>
      AndroidWidgetLaunchState(isSettingsLaunchPending: settings);
}

class _LoadedGroups extends GroupTimelineGroupSelectionNotifier {
  @override
  GroupTimelineGroupSelectionState build() =>
      const GroupTimelineGroupSelectionState(
        status: GroupTimelineGroupSelectionStatus.loaded,
        memberId: 'local-member',
      );
}

@GenerateMocks([GetCurrentMemberUseCase, GetGroupsWithMembersUsecase])
void main() {
  testWidgets('本人取得を再試行して年表を初期取得し認証を解決しない', (tester) async {
    final current = MockGetCurrentMemberUseCase();
    final groups = MockGetGroupsWithMembersUsecase();
    when(current.execute()).thenThrow(TestException('本人の読み込み失敗'));
    when(groups.execute(any)).thenAnswer((_) async => []);
    var authResolutions = 0;
    final container = ProviderContainer(
      overrides: [
        ...AppCompositionRoot(AppMode.offline).overrides,
        appInitialLocationProvider.overrideWithValue('/groups'),
        getCurrentMemberUsecaseProvider.overrideWithValue(current),
        getGroupsWithMembersUsecaseProvider.overrideWithValue(groups),
        androidWidgetLaunchNotifierProvider.overrideWith(() => _IdleLaunch()),
        authServiceProvider.overrideWith((ref) {
          authResolutions++;
          throw TestException('認証は利用しない');
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pump();
    expect(find.text('再試行'), findsOneWidget);
    const member = MemberDto(id: 'local-member', displayName: '本人');
    when(current.execute()).thenAnswer((_) async => member);
    await tester.tap(find.text('再試行'));
    await tester.pump();
    await tester.pump();
    verify(groups.execute(member)).called(1);
    expect(container.read(currentMemberNotifierProvider).member, member);
    expect(authResolutions, 0);
    expect(container.read(appRouterConfigProvider).state.uri.path, '/groups');
    expect(tester.takeException(), isNull);
  });

  testWidgets('オフラインのAndroidウィジェットから認証なしで設定へ遷移する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final groups = MockGetGroupsWithMembersUsecase();
    when(groups.execute(any)).thenAnswer((_) async => []);
    var authResolutions = 0;
    final container = ProviderContainer(
      overrides: [
        ...AppCompositionRoot(AppMode.offline).overrides,
        appInitialLocationProvider.overrideWithValue('/groups'),
        getGroupsWithMembersUsecaseProvider.overrideWithValue(groups),
        currentMemberNotifierProvider.overrideWith(
          () => FakeCurrentMemberNotifier.loaded(
            const MemberDto(id: 'local-member', displayName: '本人'),
          ),
        ),
        androidWidgetLaunchNotifierProvider.overrideWith(
          () => _IdleLaunch(settings: true),
        ),
        authServiceProvider.overrideWith((ref) {
          authResolutions++;
          throw TestException('認証は利用しない');
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(appRouterConfigProvider).state.uri.path, '/settings');
    expect(authResolutions, 0);
    expect(tester.takeException(), isNull);
  });

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
