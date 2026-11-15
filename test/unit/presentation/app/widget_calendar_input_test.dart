import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/multi_group_calendar_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/calendar_group_settings_test_support.dart';
import '../features/calendar/calendar_test_support.dart';
import '../notifiers/calendar/calendar_notifier_test.mocks.dart';
import 'top_page_test_support.dart';

import 'package:memora/presentation/app/app_router.dart';

class _CalendarLaunch extends AndroidWidgetLaunchNotifier {
  _CalendarLaunch(this.destination);
  final AndroidWidgetCalendarLaunchDestination? destination;
  @override
  AndroidWidgetLaunchState build() =>
      AndroidWidgetLaunchState(resolution: destination);
}

void main() {
  final context = TopPageTestContext();
  setUp(context.setUpContext);
  for (final scenario in [
    (save: true, fromWidget: true),
    (save: false, fromWidget: true),
    (save: true, fromWidget: false),
  ]) {
    final save = scenario.save;
    final fromWidget = scenario.fromWidget;
    testWidgets(
      '${fromWidget ? 'ウィジェット' : 'カレンダー'}の入力を背面操作から守り${save ? '保存' : '破棄確認'}後に指定日へ戻る',
      (tester) async {
        final events = MockGetCalendarEventsUsecase();
        final labels = MockGetCalendarLabelsUsecase();
        final create = MockCreateCalendarEventUsecase();
        when(events.execute(any, period: anyNamed('period')))
            .thenAnswer((_) async => []);
        when(labels.execute(any)).thenAnswer((_) async => []);
        when(create.execute(any)).thenAnswer((_) async => 'new');
        final date = DateTime(2026, 11, 20);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...context.createTopPageTestOverrides(
                initialLocation: '/calendar?date=${date.toIso8601String()}',
                currentMember: context.testMember,
                androidWidgetLaunchNotifier: _CalendarLaunch(
                  fromWidget
                      ? AndroidWidgetCalendarLaunchDestination(
                          memberId: context.testMember.id,
                          groupId: null,
                          requestId: 1,
                          date: date,
                          create: true,
                          groups: context.groupsWithMembers,
                        )
                      : null,
                ),
              ),
              calendarGroupSettingsNotifierProvider.overrideWith(
                () => TestCalendarGroupSettingsNotifier(),
              ),
              calendarWidgetGroupsChangedProvider.overrideWithValue(
                () async {},
              ),
              calendarMembershipChangesProvider.overrideWithValue(null),
              refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(
                () async {},
              ),
              getCalendarEventsUsecaseProvider.overrideWithValue(events),
              getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
              createCalendarEventUsecaseProvider.overrideWithValue(create),
              watchCalendarGroupUsecaseProvider.overrideWithValue(null),
              watchCalendarEventsUsecaseProvider.overrideWithValue(null),
              watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp.router(
                routerConfig: ref.watch(appRouterConfigProvider),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (fromWidget) {
          verifyNever(events.execute(any, period: anyNamed('period')));
        } else {
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();
        }
        expect(find.byType(CalendarScreen), findsNothing);
        expect(find.byType(BottomNavigationBar), findsNothing);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'タイトル'),
          'ウィジェットから追加',
        );
        await tester.dragFrom(const Offset(0, 250), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.byType(Drawer), findsNothing);
        expect(
          find.widgetWithText(TextFormField, 'ウィジェットから追加'),
          findsOneWidget,
        );
        if (save) {
          await calendarTapVisible(tester, find.text('保存'));
        } else {
          await calendarTapVisible(tester, find.text('キャンセル'));
          await tester.pumpAndSettle();
          expect(find.text('変更内容の確認'), findsOneWidget);
          await tester.tap(find.text('編集を続ける'));
          await tester.pumpAndSettle();
          expect(
            find.widgetWithText(TextFormField, 'ウィジェットから追加'),
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.tap(find.text('破棄する'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(CalendarScreen), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CalendarScreen)),
        );
        expect(
          container
              .read(multiGroupCalendarNotifierProvider)
              .calendar
              .selectedDate,
          date,
        );
        if (save) {
          final input = verify(create.execute(captureAny)).captured.single;
          expect(input.startDateTime, DateTime.utc(2026, 11, 20));
          expect(input.groupId, 'g1');
        } else {
          verifyNever(create.execute(any));
        }
      },
    );
  }
}
