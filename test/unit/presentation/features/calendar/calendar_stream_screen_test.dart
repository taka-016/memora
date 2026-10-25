import 'package:memora/composition_root/providers/group_providers.dart';
import '../../../../helpers/calendar_group_test_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_events_usecase.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_labels_usecase.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';

import '../../../../helpers/test_exception.dart';
import '../../notifiers/calendar/calendar_stream_test_support.dart'
    show EventSource, LabelSource;
import '../../notifiers/calendar/calendar_notifier_test.mocks.dart';
import 'calendar_test_support.dart';

void main() {
  testWidgets('オンラインは手動更新を隠し編集入力と期待値を保持して監視エラーを再試行する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final events = EventSource();
    final labels = LabelSource();
    final update = MockUpdateCalendarEventUsecase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getGroupWithMembersByIdUsecaseProvider.overrideWithValue(calendarTestGroupLoader()),
          watchCalendarGroupUsecaseProvider.overrideWithValue(null),
          appClockProvider.overrideWithValue(
            FixedAppClock(DateTime(2026, 10, 1)),
          ),
          watchCalendarEventsUsecaseProvider.overrideWithValue(
            WatchCalendarEventsUsecase(events),
          ),
          watchCalendarLabelsUsecaseProvider.overrideWithValue(
            WatchCalendarLabelsUsecase(labels),
          ),
          updateCalendarEventUsecaseProvider.overrideWithValue(update),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CalendarScreen(groupId: 'g1', groupName: '家族', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    events.streams.last.addError(TestException('予定の初回取得失敗'));
    labels.streams.last.addError(TestException('ラベルの初回取得失敗'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('予定はまだ取得できていません'), findsOneWidget);
    expect(find.textContaining('色ラベルはまだ取得できていません'), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('再試行'));
    await tester.runAsync(() => Future<void>(() {}));
    await tester.pump();
    final original = calendarTestEvent('e', '編集前').copyWith(version: 1);
    events.streams.last.add([original]);
    labels.streams.last.add([calendarTestFamily]);
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('再読み込み'), findsNothing);
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '編集前'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '入力中');
    events.streams.last.add([original.copyWith(title: '他者の更新', version: 2)]);
    await tester.pump();
    expect(find.widgetWithText(TextFormField, '入力中'), findsOneWidget);
    when(update.execute(any)).thenThrow(TestException('競合'));
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.widgetWithText(TextFormField, '入力中'), findsOneWidget);
    expect(verify(update.execute(captureAny)).captured.single.version, 1);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(CalendarScreen))).pop();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarScreen)),
    );
    events.streams.last.addError(TestException('監視失敗'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('自動更新'), findsOneWidget);
    expect(
      container.read(calendarNotifierProvider('g1')).events.single.title,
      '他者の更新',
    );
    await tester.tap(find.text('再試行'));
    await tester.runAsync(() => Future<void>(() {}));
    await tester.pump();
    expect(events.cancelled, 2);
    events.streams.last.add([]);
    labels.streams.last.add([calendarTestFamily]);
    await tester.pump();
    await tester.pump();
    expect(find.text('再試行'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      for (final stream in events.streams) {
        await stream.close();
      }
      for (final stream in labels.streams) {
        await stream.close();
      }
    });
  });
}
