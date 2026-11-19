import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final hasChanges in [false, true]) {
    testWidgets(
      hasChanges
          ? '複製の破棄確認から編集を続けられ、破棄すると保存済みの予定を複製する'
          : '予定の複製では日時が空欄で、入力すると別の予定として保存できる',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final original = calendarTestEvent('original', '元の予定').copyWith(
          startDateTime: DateTime(2026, 10, 1, 9),
          url: 'https://example.com',
          memo: '複製するメモ',
          locationName: '集合場所',
          latitude: 35.0,
          longitude: 139.0,
          notificationMinutesBefore: [30],
        );
        final harness = CalendarTestHarness()..savedEvents.add(original);
        await harness.pump(tester);
        await calendarTapVisible(tester, find.byKey(calendarTestDay2));
        await tester.pump();
        await calendarTapVisible(tester, find.byKey(calendarTestDay2));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, original.title));
        await tester.pumpAndSettle();

        final duplicate = find.byTooltip('予定を複製');
        final title = find.widgetWithText(TextFormField, 'タイトル');
        if (hasChanges) {
          await tester.enterText(title, '編集中の予定');
          await tester.pump();
          await tester.tap(duplicate);
          await tester.pumpAndSettle();
          expect(find.text('変更内容の確認'), findsOneWidget);
          await tester.tap(find.text('編集を続ける'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(TextFormField, '編集中の予定'), findsOneWidget);
        }

        await tester.tap(duplicate);
        await tester.pumpAndSettle();
        if (hasChanges) {
          await tester.tap(find.text('破棄する'));
          await tester.pumpAndSettle();
        }
        expect(find.text('変更内容の確認'), findsNothing);
        expect(find.text('予定を追加'), findsOneWidget);
        expect(duplicate, findsNothing);
        expect(
          find.widgetWithText(TextFormField, original.title),
          findsOneWidget,
        );
        expect(find.text('開始日'), findsOneWidget);
        expect(find.text('終了日'), findsOneWidget);
        expect(find.text('開始時刻を選択'), findsOneWidget);
        expect(find.text('終了時刻を選択'), findsOneWidget);

        await calendarTapVisible(tester, find.text('保存'));
        await tester.pump();
        expect(find.text('開始日と終了日を選択してください'), findsOneWidget);
        expect(harness.savedEvents, [original]);

        await _selectDate(tester, '開始日', '20261005');
        await _selectDate(tester, '終了日', '20261005');
        await _selectTime(
          tester,
          '開始時刻を選択',
          const TimeOfDay(hour: 13, minute: 0),
        );
        await calendarTapVisible(tester, find.text('保存'));
        await tester.pump();
        expect(find.text('開始時刻と終了時刻を選択してください'), findsOneWidget);
        expect(harness.savedEvents, [original]);

        await _selectTime(
          tester,
          '終了時刻を選択',
          const TimeOfDay(hour: 14, minute: 0),
        );
        await calendarTapVisible(tester, find.text('保存'));
        await tester.pumpAndSettle();
        expect(harness.savedEvents, [
          original,
          original.copyWith(
            id: 'new',
            startDateTime: DateTime(2026, 10, 5, 13),
            endDateTime: DateTime(2026, 10, 5, 14),
          ),
        ]);
        expect(find.text('予定を編集'), findsNothing);
      },
    );
  }

  testWidgets('繰り返し予定を複製して開始日を選び直しても元の曜日を保持する', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = calendarTestEvent('series', '金曜の予定').copyWith(
      startDateTime: DateTime.utc(2026, 10, 2),
      endDateTime: DateTime.utc(2026, 10, 4),
      isAllDay: true,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR',
    );
    final harness = CalendarTestHarness()..savedEvents.add(original);
    await harness.pump(tester);
    final saturday = find.byKey(const Key('calendar_day_2026_10_3'));
    await calendarTapVisible(tester, saturday);
    await tester.pump();
    await calendarTapVisible(tester, saturday);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, original.title));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('予定を複製'));
    await tester.pumpAndSettle();

    await _selectDate(tester, '開始日', '20261009');
    await _selectDate(tester, '終了日', '20261009');
    await calendarTapVisible(tester, find.text('保存'));
    await tester.pumpAndSettle();

    expect(harness.savedEvents, hasLength(2));
    final copy = harness.savedEvents.last;
    expect(copy.startDateTime, DateTime.utc(2026, 10, 9));
    expect(copy.endDateTime, DateTime.utc(2026, 10, 10));
    expect(copy.recurrenceRule, original.recurrenceRule);
    expect(copy.originalStartDateTime, isNull);
  });
}

Future<void> _selectDate(WidgetTester tester, String label, String date) async {
  await calendarTapVisible(tester, find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('date_header')));
  await tester.pump();
  await tester.enterText(find.byKey(const Key('date_field')), date);
  await tester.tap(find.text('確定'));
  await tester.pumpAndSettle();
}

Future<void> _selectTime(
  WidgetTester tester,
  String label,
  TimeOfDay time,
) async {
  await calendarTapVisible(tester, find.text(label));
  await tester.pumpAndSettle();
  Navigator.of(tester.element(find.byType(TimePickerDialog))).pop(time);
  await tester.pumpAndSettle();
}
