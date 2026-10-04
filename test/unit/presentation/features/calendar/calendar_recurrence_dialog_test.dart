import 'package:memora/presentation/shared/dialogs/custom_date_picker_dialog.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('予定入力からカスタムの複数曜日・間隔・回数を確認して保存できる', (tester) async {
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '定例');
    await tester.ensureVisible(find.text('繰り返さない'));
    await tester.tap(find.text('繰り返さない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('カスタム').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextFormField, '間隔'), '2');
    await tester.tap(find.widgetWithText(FilterChip, '木'));
    await tester.tap(find.widgetWithText(FilterChip, '土'));
    await tester.tap(find.text('終了しない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('回数指定').last);
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, '回数'), '10');
    await tester.ensureVisible(find.text('決定').last);
    await tester.tap(find.text('決定').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2週間ごとの木・土曜日、10回'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final saved =
        verify(harness.create.execute(captureAny)).captured.single
            as CalendarEventDto;
    expect(saved.recurrenceRule, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TH,SA;COUNT=10');
    expect(tester.takeException(), isNull);
  });
  testWidgets('単発予定を毎日に変更し繰り返し予定へ保存できる', (tester) async {
    final harness = CalendarTestHarness()
      ..savedEvents.add(calendarTestEvent('e', '予定'));
    await harness.pump(tester);
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ListTile, '予定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('繰り返さない'));
    await tester.tap(find.text('繰り返さない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('毎日').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final saved =
        verify(harness.update.execute(captureAny)).captured.single
            as CalendarEventDto;
    expect(saved.recurrenceRule, 'FREQ=DAILY');
    expect(saved.timeZone, 'Asia/Tokyo');
  });
  for (final allDay in [true, false]) {
    for (final scope in [
      CalendarChangeScope.all,
      CalendarChangeScope.following,
    ]) {
      testWidgets('終日区分が親と異なる個別回から系列を編集して終了条件を変換する（$allDay・$scope）', (
        tester,
      ) async {
        final source = CalendarEventDto(
          id: 'e',
          groupId: 'g1',
          labelId: 'family',
          title: '系列',
          startDateTime: DateTime.utc(2026, 10, 2, allDay ? 0 : 9),
          endDateTime: DateTime.utc(2026, 10, 2, allDay ? 0 : 10),
          isAllDay: allDay,
          timeZone: allDay ? null : 'Asia/Tokyo',
          recurrenceRule: allDay
              ? 'FREQ=DAILY;UNTIL=20261005'
              : 'FREQ=DAILY;UNTIL=20261005T145959Z',
          overrides: [
            CalendarEventOverride(
              originalStartDateTime: DateTime.utc(2026, 10, 2, allDay ? 0 : 9),
              isCancelled: false,
              title: '変更済み',
              labelId: 'family',
              isAllDay: !allDay,
              startDateTime: DateTime.utc(2026, 10, 2, allDay ? 9 : 0),
              endDateTime: DateTime.utc(2026, 10, 2, allDay ? 10 : 0),
            ),
          ],
        );
        final harness = CalendarTestHarness()..savedEvents.add(source);
        await harness.pump(tester);
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.widgetWithText(ListTile, '変更済み'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'タイトル'),
          '再編集',
        );
        await tester.tap(find.text('保存'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(
          find.text(scope == CalendarChangeScope.all ? 'すべての予定' : 'この予定とこれ以降'),
        );
        await tester.pump();
        await tester.tap(find.text('変更する'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final saved =
            verify(
                  harness.changeRecurrence.execute(
                    any,
                    any,
                    scope,
                    changes: captureAnyNamed('changes'),
                  ),
                ).captured.single
                as CalendarEventDto;
        expect(
          saved.recurrenceRule,
          allDay
              ? 'FREQ=DAILY;UNTIL=20261005T145959Z'
              : 'FREQ=DAILY;UNTIL=20261005',
        );
      });
    }
  }
  for (final allDay in [true, false]) {
    for (final scope in [
      CalendarChangeScope.all,
      CalendarChangeScope.following,
    ]) {
      testWidgets('日付と終日区分を同時に変更して系列の保存へ進める（$allDay・$scope）', (tester) async {
        final harness = CalendarTestHarness()
          ..savedEvents.add(
            CalendarEventDto(
              id: 'e',
              groupId: 'g1',
              labelId: 'family',
              title: '週の系列',
              startDateTime: DateTime.utc(2026, 10, 2, allDay ? 0 : 9),
              endDateTime: DateTime.utc(2026, 10, 5, allDay ? 0 : 9),
              isAllDay: allDay,
              timeZone: allDay ? null : 'Asia/Tokyo',
              recurrenceRule: allDay
                  ? 'FREQ=WEEKLY;BYDAY=FR;UNTIL=20270101'
                  : 'FREQ=WEEKLY;BYDAY=FR;UNTIL=20270101T145959Z',
            ),
          );
        await harness.pump(tester);
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.widgetWithText(ListTile, '週の系列'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('開始日: 2026/10/2'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(CustomDatePickerDialog), findsOneWidget);
        await tester.tap(find.byKey(const Key('date_header')));
        await tester.pump();
        await tester.enterText(find.byKey(const Key('date_field')), '20261003');
        await tester.tap(find.text('確定'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('終日'));
        await tester.pump();
        await tester.tap(find.text('保存'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(
          find.text(scope == CalendarChangeScope.all ? 'すべての予定' : 'この予定とこれ以降'),
        );
        await tester.pump();
        await tester.tap(find.text('変更する'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final saved =
            verify(
                  harness.changeRecurrence.execute(
                    any,
                    any,
                    scope,
                    changes: captureAnyNamed('changes'),
                  ),
                ).captured.single
                as CalendarEventDto;
        expect(saved.isAllDay, !allDay);
        expect(
          saved.recurrenceRule,
          endsWith(allDay ? 'UNTIL=20270101T145959Z' : 'UNTIL=20270101'),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final until in [false, true]) {
    testWidgets('23時59分でも選択画面の初期日と確定後の日付を維持する（$until）', (tester) async {
      final source = calendarTestEvent('e', '夜の予定').copyWith(
        startDateTime: DateTime.utc(2026, 10, 2, until ? 9 : 22),
        endDateTime: DateTime.utc(2026, 10, 2, until ? 10 : 23, until ? 0 : 59),
        recurrenceRule: until ? 'FREQ=DAILY;UNTIL=20261005T145959Z' : null,
        timeZone: until ? 'Asia/Tokyo' : null,
      );
      final harness = CalendarTestHarness()..savedEvents.add(source);
      await harness.pump(tester);
      await tester.tap(find.byKey(calendarTestDay2));
      await tester.pump();
      await tester.tap(find.byKey(calendarTestDay2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(ListTile, '夜の予定'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (until) {
        final summary = find.text('毎日、2026/10/5まで');
        await tester.ensureVisible(summary);
        await tester.tap(summary);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('カスタム').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      final date = until
          ? find.descendant(
              of: find.widgetWithText(AlertDialog, 'カスタムの繰り返し'),
              matching: find.textContaining('終了日:'),
            )
          : find.text('終了日: 2026/10/2');
      await tester.ensureVisible(date);
      await tester.tap(date);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CustomDatePickerDialog), findsOneWidget);
      expect(
        find.text(until ? '2026年10月5日 (月)' : '2026年10月2日 (金)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('date_header')));
      await tester.pump();
      final input = tester.widget<TextField>(
        find.byKey(const Key('date_field')),
      );
      expect(input.controller!.text, until ? '2026/10/05' : '2026/10/02');
      await tester.tap(find.text('確定'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (until) {
        await tester.ensureVisible(find.text('決定').last);
        await tester.tap(find.text('決定').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (until) {
        await tester.tap(find.text('すべての予定'));
        await tester.pump();
        await tester.tap(find.text('変更する'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final saved =
            verify(
                  harness.changeRecurrence.execute(
                    any,
                    any,
                    CalendarChangeScope.all,
                    changes: captureAnyNamed('changes'),
                  ),
                ).captured.single
                as CalendarEventDto;
        expect(saved.recurrenceRule, source.recurrenceRule);
      } else {
        final saved =
            verify(harness.update.execute(captureAny)).captured.single
                as CalendarEventDto;
        expect(saved.endDateTime, source.endDateTime);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('繰り返しの終了日も共通の日付直接入力で設定して保存できる', (tester) async {
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '期日付き');
    await tester.ensureVisible(find.text('繰り返さない'));
    await tester.tap(find.text('繰り返さない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('カスタム').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilterChip, '木'));
    await tester.ensureVisible(find.text('終了しない'));
    await tester.tap(find.text('終了しない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('終了日指定').last);
    await tester.pump();
    final until = find.descendant(
      of: find.widgetWithText(AlertDialog, 'カスタムの繰り返し'),
      matching: find.textContaining('終了日:'),
    );
    await tester.ensureVisible(until);
    await tester.tap(until);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CustomDatePickerDialog), findsOneWidget);
    await tester.tap(find.byKey(const Key('date_header')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('date_field')), '20261031');
    await tester.tap(find.text('確定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('決定').last);
    await tester.tap(find.text('決定').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final saved =
        verify(harness.create.execute(captureAny)).captured.single
            as CalendarEventDto;
    expect(saved.recurrenceRule, endsWith('UNTIL=20261031'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('繰り返しの編集と削除は範囲を確認してUseCaseへ渡す', (tester) async {
    final harness = CalendarTestHarness()
      ..savedEvents.add(
        calendarTestEvent('e', '定例').copyWith(
          recurrenceRule: 'FREQ=DAILY;COUNT=3',
          timeZone: 'Asia/Tokyo',
        ),
      );
    await harness.pump(tester);
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ListTile, '定例'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '変更');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('この予定とこれ以降'));
    await tester.pump();
    expect(find.textContaining('対象範囲の個別回の上書き'), findsOneWidget);
    await tester.tap(find.text('変更する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    verify(
      harness.changeRecurrence.execute(
        any,
        any,
        CalendarChangeScope.following,
        changes: anyNamed('changes'),
      ),
    ).called(1);
    await tester.tap(find.widgetWithText(ListTile, '定例'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('削除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('この予定のみ'));
    await tester.pump();
    await tester.tap(find.text('削除する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    verify(harness.changeRecurrence.execute(any, any, CalendarChangeScope.only))
        .called(1);
    verifyZeroInteractions(harness.update);
    verifyZeroInteractions(harness.delete);
    expect(tester.takeException(), isNull);
  });
}
