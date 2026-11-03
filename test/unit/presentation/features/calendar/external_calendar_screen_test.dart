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
  List<String> get eventAccounts =>
      state.events.map((v) => v.accountId).toList();
  @override
  ExternalCalendarState build() =>
      ExternalCalendarState(month: DateTime(2026, 10));
  @override
  Future<void> initialize() async {}
  @override
  Future<void> setPeriod(DateTime day) async {}
  @override
  Future<void> connect() async {
    final id = state.connections.isEmpty ? 'google' : 'second';
    state = state.copyWith(
      connections: [
        ...state.connections,
        ExternalCalendarConnection(
          account: ExternalCalendarAccount(id: id, email: '$id@example.com'),
        ),
      ],
      calendarsByAccount: {
        ...state.calendarsByAccount,
        id: [const ExternalCalendarDto(id: 'personal', name: '個人')],
      },
    );
  }

  @override
  Future<void> selectCalendars(String accountId, Set<String> ids) async {
    selected = ids.contains('personal');
    state = state.copyWith(
      connections: [
        for (final connection in state.connections)
          if (connection.account.id == accountId)
            ExternalCalendarConnection(
              account: connection.account,
              calendarIds: ids,
            )
          else
            connection,
      ],
      eventsByAccount: {
        ...state.eventsByAccount,
        accountId: selected
            ? [
                ExternalCalendarEventDto(
                  accountId: accountId,
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
      },
    );
  }

  @override
  Future<void> disconnect(String accountId) async {
    disconnected = true;
    state = state.copyWith(
      connections: state.connections
          .where((v) => v.account.id != accountId)
          .toList(),
      calendarsByAccount: {...state.calendarsByAccount}..remove(accountId),
      eventsByAccount: {...state.eventsByAccount}..remove(accountId),
    );
  }

  @override
  Future<void> refresh({String? accountId}) async {
    retries++;
    state = state.copyWith(error: '');
  }

  void fail() {
    state = state.copyWith(
      error: '外部予定を取得できません',
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
    await external.selectCalendars('google', {'personal'});
    external.fail();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('外部予定を取得できません'), findsNothing);
    expect(find.text('Google予定を再取得'), findsNothing);
    await tester.tap(find.byTooltip('Googleカレンダー連携'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('カレンダー一覧を再取得'));
    await tester.tap(find.text('カレンダー一覧を再取得'));
    await tester.pump();
    expect(external.retries, 1);
    await tester.ensureVisible(find.text('連携を解除'));
    await tester.tap(find.text('連携を解除'));
    await tester.pump();
    expect(external.disconnected, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('2アカウントを追加してそれぞれの予定を表示し一方だけ解除できる', (tester) async {
    final external = _ExternalCalendar();
    await CalendarTestHarness().pump(tester, externalCalendar: external);
    await tester.tap(find.byTooltip('Googleカレンダー連携'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Googleアカウントを選択して連携'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CheckboxListTile, '個人'));
    await tester.pump();
    await tester.ensureVisible(find.text('Googleアカウントを追加'));
    await tester.tap(find.text('Googleアカウントを追加'));
    await tester.pump();
    expect(find.text('google@example.com'), findsOneWidget);
    expect(find.text('second@example.com'), findsOneWidget);
    final secondSection = find.byKey(const ValueKey('external_account_second'));
    final secondCalendar = find.descendant(
      of: secondSection,
      matching: find.byType(CheckboxListTile),
    );
    await tester.ensureVisible(secondCalendar);
    await tester.tap(secondCalendar);
    await tester.pump();
    expect(external.eventAccounts, ['google', 'second']);
    final firstSection = find.byKey(const ValueKey('external_account_google'));
    final disconnect = find.descendant(
      of: firstSection,
      matching: find.text('連携を解除'),
    );
    await tester.ensureVisible(disconnect);
    await tester.tap(disconnect);
    await tester.pump();
    expect(find.text('google@example.com'), findsNothing);
    expect(find.text('second@example.com'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('自分の予定 · 個人'), findsWidgets);
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
    expect(find.text('Googleカレンダーの予定'), findsOneWidget);
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
    expect(find.textContaining('最新の情報を取得できていません'), findsNothing);
    expect(find.text('外部予定を取得できません'), findsNothing);
    expect(find.text('家族の予定'), findsWidgets);
    await tester.tap(find.byTooltip('Googleカレンダー連携'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カレンダー一覧を再取得'));
    await tester.pump();
    expect(external.retries, 1);
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
