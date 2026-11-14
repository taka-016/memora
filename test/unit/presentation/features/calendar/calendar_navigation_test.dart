import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/composition_root/providers/group_providers.dart';

import '../../../../helpers/calendar_group_test_support.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

import '../../app/top_page_test_support.dart';
import '../../notifiers/calendar/calendar_notifier_test.mocks.dart';

void main() {
  final support = TopPageTestContext();
  setUp(support.setUpContext);
  Future<MockGetCalendarEventsUsecase> pump(
    WidgetTester tester, {
    int count = 2,
    String location = '/calendar',
    AndroidWidgetLaunchNotifier? launch,
  }) async {
    final events = MockGetCalendarEventsUsecase();
    final labels = MockGetCalendarLabelsUsecase();
    when(events.execute(any, period: anyNamed('period')))
        .thenAnswer((_) async => []);
    when(labels.execute(any)).thenAnswer((_) async => []);
    final groups = support.groupsWithMembers.take(count).toList();
    support.stubFreshGroupsWithMembers(groups);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarSettingsOwnerProvider.overrideWithValue('online:self'),
          calendarSettingsMemberIdProvider.overrideWithValue('default_member'),
          getGroupWithMembersByIdUsecaseProvider.overrideWithValue(
            calendarTestGroupLoader(),
          ),
          watchCalendarGroupUsecaseProvider.overrideWithValue(null),
          watchCalendarEventsUsecaseProvider.overrideWithValue(null),
          watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
          ...support.createTopPageTestOverrides(
            availableGroupsWithMembers: groups,
            initialLocation: location,
            androidWidgetLaunchNotifier: launch,
          ),
          getCalendarEventsUsecaseProvider.overrideWithValue(events),
          getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(appRouterConfigProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return events;
  }

  testWidgets('グループが1件でも起動URLの日付と追加要求を自動選択で上書きしない', (tester) async {
    await pump(
      tester,
      count: 1,
      location: '/groups',
      launch: _CalendarLaunchNotifier(),
    );
    expect(find.byType(CalendarEventDialog), findsOneWidget);
    expect(find.text('開始日: 2027/1/1'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarEventDialog)),
    );
    final router = container.read(appRouterConfigProvider);
    expect(router.state.uri.queryParameters['create'], 'true');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    router.go(
      const CalendarRoute(
        groupId: '1',
        date: '2027-01-01',
        create: true,
        request: 2,
      ).location,
    );
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventDialog), findsOneWidget);
  });

  Future<void> select(WidgetTester tester, List<String> names) async {
    await tester.tap(find.byTooltip('表示グループの選択'));
    await tester.pumpAndSettle();
    for (final name in names) {
      await tester.tap(find.text(name));
    }
    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();
  }

  testWidgets('カレンダーの入口は保存先グループを必要としない', (tester) async {
    expect(const CalendarRoute().location, '/calendar');
    final events = await pump(tester);
    expect(find.byKey(const Key('calendar_screen')), findsOneWidget);
    verifyZeroInteractions(events);
    await select(tester, ['グループ1', 'グループ2']);
    verify(events.execute('1', period: anyNamed('period'))).called(1);
    verify(events.execute('2', period: anyNamed('period'))).called(1);
    expect(find.byTooltip('グループ選択へ戻る'), findsNothing);
  });
  testWidgets('所属1件の初期選択はURLのグループではなく実際の所属を使う', (tester) async {
    final events = await pump(
      tester,
      count: 1,
      location: const CalendarRoute(groupId: 'other').location,
    );
    expect(find.text('表示するグループを選択してください'), findsNothing);
    verify(events.execute('1', period: anyNamed('period'))).called(1);
    verifyNever(events.execute('other', period: anyNamed('period')));
  });
  testWidgets('下部メニューのカレンダーを再タップしても同じ月と選択日を維持する', (tester) async {
    await pump(tester, count: 1);
    await tester.tap(find.byTooltip('次の月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年6月'), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text('カレンダー'),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('2026年6月'), findsOneWidget);
  });
  testWidgets('設定表示中のグループ更新で背面のカレンダーが画面を切り替えない', (tester) async {
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('calendar_screen'))),
    );
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    container
        .read(groupTimelineGroupSelectionNotifierProvider.notifier)
        .setLoadedGroups(
          memberId: 'default_member',
          groups: [support.groupsWithMembers[1]],
        );
    await tester.pumpAndSettle();
    final router = container.read(appRouterConfigProvider);
    expect(router.state.uri.path, const SettingsRoute().location);
  });
  testWidgets('所属が失効したら既存の予定表示を閉じる', (tester) async {
    await pump(tester);
    await select(tester, ['グループ1']);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('calendar_screen'))),
    );
    container
        .read(groupTimelineGroupSelectionNotifierProvider.notifier)
        .setLoadedGroups(
          memberId: 'default_member',
          groups: [support.groupsWithMembers[1]],
        );
    await tester.pumpAndSettle();
    expect(find.text('表示するグループを選択してください'), findsOneWidget);
  });
}

class _CalendarLaunchNotifier extends AndroidWidgetLaunchNotifier {
  @override
  AndroidWidgetLaunchState build() => AndroidWidgetLaunchState(
    pendingCalendarUri: Uri.parse(
      'memoraWidget://openCalendar?groupId=1&date=2027-01-01&create=true',
    ),
  );
}
