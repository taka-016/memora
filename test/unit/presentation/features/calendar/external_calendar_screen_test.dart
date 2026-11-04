import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

import 'calendar_test_support.dart';

class _ExternalCalendar extends ExternalCalendarNotifier {
  int retries = 0;
  bool grantsPermission = true;
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
  Future<void> requestAccess() async {
    if (!grantsPermission) {
      state = state.copyWith(error: '端末の設定でカレンダーの読み取りを許可してください');
      return;
    }
    state = state.copyWith(
      hasPermission: true,
      connections: [
        for (final id in ['first', 'second'])
          ExternalCalendarConnection(
            account: ExternalCalendarAccount(id: id, name: '$id@example.com'),
          ),
      ],
      calendarsByAccount: {
        for (final id in ['first', 'second'])
          id: [const ExternalCalendarDto(id: 'personal', name: '個人')],
      },
    );
  }

  @override
  Future<void> selectCalendars(String accountId, Set<String> ids) async {
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
        accountId: ids.isNotEmpty
            ? [
                ExternalCalendarEventDto(
                  accountId: accountId,
                  id: 'external',
                  calendarId: 'personal',
                  calendarName: '個人',
                  title: '$accountIdの予定',
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
  Future<void> refresh() async {
    retries++;
    state = state.copyWith(error: '');
  }

  void fail() {
    state = state.copyWith(error: '端末の予定を取得できません');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Finder section(String id) => find.byKey(ValueKey('external_account_$id'));
  Finder checkbox(String id) =>
      find.descendant(of: section(id), matching: find.byType(CheckboxListTile));

  testWidgets('端末の許可後に複数アカウントを選び一方の選択だけを解除できる', (tester) async {
    final external = _ExternalCalendar();
    await CalendarTestHarness().pump(tester, externalCalendar: external);
    await tester.tap(find.byTooltip('端末カレンダー連携'));
    await tester.pumpAndSettle();
    expect(find.text('Googleアカウントを追加'), findsNothing);
    await tester.tap(find.text('カレンダーへのアクセスを許可'));
    await tester.pump();
    expect(find.text('first@example.com'), findsOneWidget);
    expect(find.text('second@example.com'), findsOneWidget);
    await tester.tap(checkbox('first'));
    await tester.pump();
    await tester.ensureVisible(checkbox('second'));
    await tester.tap(checkbox('second'));
    await tester.pump();
    expect(external.eventAccounts, ['first', 'second']);
    final clear = find.descendant(
      of: section('first'),
      matching: find.text('選択を解除'),
    );
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pump();
    expect(external.eventAccounts, ['second']);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('secondの予定'), findsWidgets);
    expect(find.text('firstの予定'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('端末の予定を共有予定と重ねて表示し詳細では編集操作や読み取り専用表記を出さない', (tester) async {
    final external = _ExternalCalendar();
    final harness = CalendarTestHarness()
      ..savedEvents.add(calendarTestEvent('shared', '家族の予定'));
    await harness.pump(tester, externalCalendar: external);
    await tester.tap(find.byTooltip('端末カレンダー連携'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カレンダーへのアクセスを許可'));
    await tester.pump();
    await tester.tap(checkbox('first'));
    await tester.pump();
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '家族の予定'), findsOneWidget);
    expect(find.text('端末-first@example.com（個人）'), findsOneWidget);
    expect(find.textContaining('端末 · 個人'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'firstの予定'));
    await tester.pumpAndSettle();
    expect(find.text('端末カレンダーの予定'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('端末-first@example.com（個人）'),
      ),
      findsOneWidget,
    );
    expect(find.text('予定の本文'), findsOneWidget);
    expect(find.textContaining('2週間ごと'), findsOneWidget);
    expect(find.textContaining('読み取り専用'), findsNothing);
    expect(find.text('保存'), findsNothing);
    expect(find.text('削除'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小画面でもエラーは連携設定内だけに表示し一覧更新で再試行できる', (tester) async {
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
    await external.requestAccess();
    external.fail();
    await tester.pump();
    expect(find.text('端末の予定を取得できません'), findsNothing);
    await tester.tap(find.byTooltip('端末カレンダー連携'));
    await tester.pumpAndSettle();
    expect(find.text('端末の予定を取得できません'), findsOneWidget);
    await tester.ensureVisible(find.text('カレンダー一覧を更新'));
    await tester.tap(find.text('カレンダー一覧を更新'));
    await tester.pump();
    expect(external.retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('許可を拒否した場合は端末設定で許可する案内を表示する', (tester) async {
    final external = _ExternalCalendar()..grantsPermission = false;
    await CalendarTestHarness().pump(tester, externalCalendar: external);
    await tester.tap(find.byTooltip('端末カレンダー連携'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カレンダーへのアクセスを許可'));
    await tester.pump();
    expect(find.text('端末の設定でカレンダーの読み取りを許可してください'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });
}
