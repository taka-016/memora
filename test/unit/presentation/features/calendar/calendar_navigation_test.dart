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
  }) async {
    final events = MockGetCalendarEventsUsecase();
    final labels = MockGetCalendarLabelsUsecase();
    when(events.execute(any)).thenAnswer((_) async => []);
    when(labels.execute(any)).thenAnswer((_) async => []);
    final groups = support.groupsWithMembers.take(count).toList();
    support.stubFreshGroupsWithMembers(groups);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...support.createTopPageTestOverrides(
            availableGroupsWithMembers: groups,
            initialLocation: location,
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

  testWidgets('複数グループは選択後に月表示を開き戻ると別グループに切り替えられる', (tester) async {
    final events = await pump(tester);
    expect(find.byKey(const Key('calendar_group_list')), findsOneWidget);
    verifyZeroInteractions(events);
    await tester.tap(find.text('グループ1'));
    await tester.pumpAndSettle();
    expect(find.text('グループ1のカレンダー'), findsOneWidget);
    await tester.tap(find.byTooltip('グループ選択へ戻る'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar_group_list')), findsOneWidget);
    await tester.tap(find.text('グループ2'));
    await tester.pumpAndSettle();
    expect(find.text('グループ2のカレンダー'), findsOneWidget);
    verify(events.execute('1')).called(1);
    verify(events.execute('2')).called(1);
  });
  testWidgets('1件のグループは選択を省略し戻る操作では選択画面を維持する', (tester) async {
    await pump(tester, count: 1);
    expect(find.text('グループ1のカレンダー'), findsOneWidget);
    expect(find.byKey(const Key('calendar_group_list')), findsNothing);
    await tester.tap(find.byTooltip('グループ選択へ戻る'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar_group_list')), findsOneWidget);
  });
  testWidgets('所属していないグループの直接URLは予定を取得せず選択へ戻る', (tester) async {
    final events = await pump(
      tester,
      location: const CalendarRoute(groupId: 'other').location,
    );
    expect(find.byKey(const Key('calendar_group_list')), findsOneWidget);
    verifyZeroInteractions(events);
  });
  testWidgets('メニューを開き直しても同じ月と選択日を維持する', (tester) async {
    await pump(tester, count: 1);
    await tester.tap(find.byTooltip('次の月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年6月'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カレンダー'));
    await tester.pumpAndSettle();
    expect(find.text('2026年6月'), findsOneWidget);
  });
  testWidgets('所属が失効したら既存の予定表示を閉じる', (tester) async {
    await pump(tester);
    await tester.tap(find.text('グループ1'));
    await tester.pumpAndSettle();
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
    expect(find.text('グループ1のカレンダー'), findsNothing);
  });
}
