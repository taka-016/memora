import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

import 'calendar_test_support.dart';

class _ExternalCalendar extends ExternalCalendarNotifier {
  bool selected = false;
  bool disconnected = false;
  int retries = 0;
  @override
  ExternalCalendarState build() =>
      ExternalCalendarState(month: DateTime(2026, 10));
  @override
  Future<void> initialize() async {}
  @override
  Future<void> setPeriod(DateTime day) async {}
  @override
  Future<void> connect() async {
    state = state.copyWith(
      connection: ExternalCalendarConnection(
        account: const ExternalCalendarAccount(
          id: 'google',
          email: 'me@example.com',
        ),
      ),
      calendars: [const ExternalCalendarDto(id: 'personal', name: '個人')],
    );
  }

  @override
  Future<void> selectCalendars(Set<String> ids) async {
    selected = ids.contains('personal');
    state = state.copyWith(
      connection: ExternalCalendarConnection(
        account: state.connection!.account,
        calendarIds: ids,
      ),
      events: selected
          ? [
              ExternalCalendarEventDto(
                id: 'external',
                calendarId: 'personal',
                calendarName: '個人',
                title: '自分の予定',
                memo: '予定の本文',
                isRecurring: true,
                recurrence: [
                  'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR;COUNT=10',
                ],
                timeZone: 'Asia/Tokyo',
                startDateTime: DateTime(2026, 10, 2, 9),
                endDateTime: DateTime(2026, 10, 2, 10),
                isAllDay: false,
              ),
            ]
          : [],
    );
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
    state = ExternalCalendarState(month: state.month);
  }

  @override
  Future<void> refresh() async {
    retries++;
    state = state.copyWith(error: '', isStale: false);
  }

  void fail() {
    state = state.copyWith(
      error: '外部予定を取得できません',
      isStale: true,
      failure: ExternalCalendarFailure.network,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('小画面で文字を拡大しても外部取得エラーをスクロールして再試行できる', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final external = _ExternalCalendar();
    await CalendarTestHarness().pump(
      tester,
      externalCalendar: external,
      textScale: 2,
    );
    await external.connect();
    await external.selectCalendars({'personal'});
    external.fail();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Google予定を再取得'));
    await tester.tap(find.text('Google予定を再取得'));
    await tester.pump();
    expect(external.retries, 1);
    await tester.tap(find.byTooltip('Googleカレンダー連携'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('連携を解除'));
    await tester.tap(find.text('連携を解除'));
    await tester.pump();
    expect(external.disconnected, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('連携・選択した予定を共有予定と重ねて読み取り専用で表示し解除する', (tester) async {
    final external = _ExternalCalendar();
    final harness = CalendarTestHarness()
      ..savedEvents.add(calendarTestEvent('shared', '家族の予定'));
    await harness.pump(tester, externalCalendar: external);
    await tester.tap(find.byTooltip('Googleカレンダー連携'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Googleアカウントを選択して連携'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CheckboxListTile, '個人'));
    await tester.pump();
    expect(external.selected, isTrue);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('自分の予定 · 個人'), findsWidgets);
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '家族の予定'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, '自分の予定 · 個人'));
    await tester.pumpAndSettle();
    expect(find.text('予定の本文'), findsOneWidget);
    expect(find.text('Googleカレンダーの予定（読み取り専用）'), findsOneWidget);
    expect(find.text('繰り返し予定'), findsOneWidget);
    expect(find.textContaining('2週間ごと'), findsOneWidget);
    expect(find.textContaining('月・金'), findsOneWidget);
    expect(find.textContaining('10回'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
    expect(find.text('削除'), findsNothing);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('予定一覧を閉じる'));
    await tester.pumpAndSettle();
    external.fail();
    await tester.pump();
    expect(find.textContaining('最新の情報を取得できていません'), findsOneWidget);
    expect(find.text('家族の予定'), findsWidgets);
    await tester.tap(find.text('Google予定を再取得'));
    await tester.pump();
    expect(external.retries, 1);
    await tester.tap(find.byTooltip('Googleカレンダー連携'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('連携を解除'));
    await tester.pump();
    expect(external.disconnected, isTrue);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('自分の予定 · 個人'), findsNothing);
    expect(find.text('家族の予定'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
