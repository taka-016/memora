import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final move in [false, true]) {
    testWidgets('月末補正回の同日確定は基準維持し個別移動は終了条件外も許可する（$move）', (tester) async {
      final source = calendarTestEvent('e', '月末の予定').copyWith(
        isAllDay: true,
        startDateTime: DateTime.utc(2026, 1, 31),
        endDateTime: DateTime.utc(2026, 1, 31),
        recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=31;UNTIL=20260228',
      );
      final harness = CalendarTestHarness()..savedEvents.add(source);
      await harness.pump(tester, now: DateTime(2026, 2, 1));
      final day = find.byKey(const Key('calendar_day_2026_2_28'));
      await tester.tap(day);
      await tester.pump();
      await tester.tap(day);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(ListTile, '月末の予定'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('開始日: 2026/2/28'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('date_header')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('date_field')),
        move ? '20260301' : '20260228',
      );
      await tester.tap(find.text('確定'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (!move) expect(find.text('毎月の31日、2026/2/28まで'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (!move) {
        await tester.tap(find.text('すべての予定'));
        await tester.pump();
      }
      await tester.tap(find.text('変更する'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final saved =
          verify(
                harness.changeRecurrence.execute(
                  any,
                  any,
                  move ? CalendarChangeScope.only : CalendarChangeScope.all,
                  changes: captureAnyNamed('changes'),
                ),
              ).captured.single
              as CalendarEventDto;
      expect(saved.recurrenceRule, source.recurrenceRule);
    });
  }
  testWidgets('繰り返し設定後の開始日変更で要約と保存条件が追従する', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '定例');
    await tester.ensureVisible(find.text('繰り返さない'));
    await tester.tap(find.text('繰り返さない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('毎月').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text('開始日: 2026/10/2'));
    await tester.tap(find.text('開始日: 2026/10/2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('date_header')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('date_field')), '20261010');
    await tester.tap(find.text('確定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('毎月の10日'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final saved =
        verify(harness.create.execute(captureAny)).captured.single
            as CalendarEventDto;
    expect(saved.recurrenceRule, 'FREQ=MONTHLY;BYMONTHDAY=10');
  });
  for (final allDay in [false, true]) {
    for (final days in [-2, 30]) {
      testWidgets('開始日変更で終了日も同じ日数動き期間を維持する（終日$allDay・$days日）', (tester) async {
        final source = calendarTestEvent('e', '複数日の予定').copyWith(
          isAllDay: allDay,
          startDateTime: allDay
              ? DateTime(2026, 10, 2)
              : DateTime(2026, 10, 2, 9),
          endDateTime: allDay
              ? DateTime(2026, 10, 4)
              : DateTime(2026, 10, 4, 23, 59),
        );
        final target = source.startDateTime.add(Duration(days: days));
        final expectedEnd = source.endDateTime.add(Duration(days: days));
        final harness = CalendarTestHarness()..savedEvents.add(source);
        await harness.pump(tester);
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.widgetWithText(ListTile, '複数日の予定'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('開始日: 2026/10/2'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const Key('date_header')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('date_field')),
          '${target.year}${target.month.toString().padLeft(2, '0')}${target.day.toString().padLeft(2, '0')}',
        );
        await tester.tap(find.text('確定'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(
            '終了日: ${expectedEnd.year}/${expectedEnd.month}/${expectedEnd.day}',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('保存'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final saved =
            verify(harness.update.execute(captureAny)).captured.single
                as CalendarEventDto;
        expect(saved.startDateTime, target);
        expect(saved.endDateTime, expectedEnd);
        expect(
          saved.endDateTime.difference(saved.startDateTime),
          source.endDateTime.difference(source.startDateTime),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
