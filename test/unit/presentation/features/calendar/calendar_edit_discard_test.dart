import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_notification_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<CalendarTestHarness> openEvent(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    await tester.tap(find.byTooltip('予定を追加'));
    await pumpDialog(tester);
    return harness;
  }

  for (final exit in ['キャンセル', '戻る', '外側']) {
    testWidgets('予定の変更後に$exitで閉じると共通の破棄確認が出て編集を続けられる', (tester) async {
      final harness = await openEvent(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'タイトル'),
        '編集中の予定',
      );
      await tester.pump();
      switch (exit) {
        case 'キャンセル':
          await tester.tap(find.text('キャンセル'));
        case '戻る':
          await tester.binding.handlePopRoute();
        case '外側':
          await tester.tapAt(const Offset(2, 2));
      }
      await pumpDialog(tester);
      expect(find.text('変更内容の確認'), findsOneWidget);
      await tester.tap(find.text('編集を続ける'));
      await pumpDialog(tester);
      expect(find.widgetWithText(TextFormField, '編集中の予定'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await pumpDialog(tester);
      await tester.tap(find.text('破棄する'));
      await pumpDialog(tester);
      expect(find.text('予定を追加'), findsNothing);
      expect(harness.savedEvents, isEmpty);
    });
  }
  testWidgets('取得したデフォルト通知は変更と見なさず入力を元に戻せばそのまま閉じる', (tester) async {
    await const SharedPreferencesCalendarNotificationStorage().save(
      const CalendarNotificationPreferences(allDay: [1440]),
    );
    await openEvent(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '一時入力');
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '');
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsNothing);
    expect(find.text('予定を追加'), findsNothing);
  });
  testWidgets('通知だけの変更も破棄確認し保存では確認せず保存できる', (tester) async {
    final harness = await openEvent(tester);
    await tester.ensureVisible(find.text('通知を追加'));
    await tester.tap(find.text('通知を追加'));
    await pumpDialog(tester);
    await tester.tap(find.text('予定の開始時'));
    await pumpDialog(tester);
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsOneWidget);
    await tester.tap(find.text('編集を続ける'));
    await pumpDialog(tester);
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'タイトル'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'タイトル'),
      '保存する予定',
    );
    await tester.tap(find.text('保存'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsNothing);
    expect(harness.savedEvents.single.notificationMinutesBefore, [0]);
  });
  testWidgets('繰り返し設定を破棄しても親の予定編集は変更ありのまま保持する', (tester) async {
    await openEvent(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '親の変更');
    await tester.ensureVisible(find.text('繰り返さない'));
    await tester.tap(find.text('繰り返さない'));
    await pumpDialog(tester);
    await tester.tap(find.text('カスタム'));
    await pumpDialog(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '間隔'), '2');
    await tester.pump();
    await tester.tap(find.text('キャンセル').last);
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsOneWidget);
    await tester.tap(find.text('破棄する'));
    await pumpDialog(tester);
    expect(find.text('カスタムの繰り返し'), findsNothing);
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsOneWidget);
    await tester.tap(find.text('編集を続ける'));
    await pumpDialog(tester);
    expect(find.widgetWithText(TextFormField, '親の変更'), findsOneWidget);
  });
  testWidgets('色ラベルは名前や色の変更を破棄確認し元に戻せば確認しない', (tester) async {
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await pumpDialog(tester);
    await tester.tap(find.text('ラベルを追加'));
    await pumpDialog(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '名前'), '一時的なラベル');
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsOneWidget);
    await tester.tap(find.text('編集を続ける'));
    await pumpDialog(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '名前'), '');
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('ラベルを追加'), findsOneWidget);
    expect(find.text('変更内容の確認'), findsNothing);
    expect(harness.savedLabels, hasLength(1));
  });
}
