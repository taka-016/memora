import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_notification_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('新規予定は終日のデフォルトを読み込み種別を切り替えると切替先の設定で保存する', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    addTearDown(tester.view.resetPhysicalSize);
    const storage = SharedPreferencesCalendarNotificationStorage();
    await storage.save(
      const CalendarNotificationPreferences(allDay: [1440], timed: [10, 60]),
    );
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('1日前'));
    expect(find.text('1日前'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('10分前'));
    expect(find.text('1日前'), findsNothing);
    expect(find.text('1時間前'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, '通知のある予定');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.savedEvents.single.notificationMinutesBefore, [10, 60]);
  });
  testWidgets('保存済みの通知はデフォルトに置き換えず確認して解除できる', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = CalendarTestHarness()
      ..savedEvents.add(
        calendarTestEvent(
          'event',
          '予定',
        ).copyWith(notificationMinutesBefore: [30]),
      );
    await harness.pump(tester);
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.tap(find.byKey(calendarTestDay2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ListTile, '予定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('30分前'));
    await tester.tap(find.byTooltip('通知を解除'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.savedEvents.single.notificationMinutesBefore, isEmpty);
  });
}
