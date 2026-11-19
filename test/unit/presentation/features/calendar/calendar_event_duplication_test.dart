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
          : '予定を複製して日時を初期化し、別の予定として保存できる',
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
        expect(find.text('開始日: 2026/10/2'), findsOneWidget);
        expect(find.text('終了日: 2026/10/2'), findsOneWidget);
        expect(find.text('00:00'), findsNWidgets(2));
        expect(harness.savedEvents, [original]);

        await calendarTapVisible(tester, find.text('保存'));
        await tester.pumpAndSettle();
        final saved = harness.savedEvents.last;
        expect(harness.savedEvents, [
          original,
          original.copyWith(
            id: 'new',
            startDateTime: DateTime(2026, 10, 2),
            endDateTime: DateTime(2026, 10, 2),
          ),
        ]);
        expect(saved.id, 'new');
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

    await calendarTapVisible(tester, find.text('開始日: 2026/10/3'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('date_header')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('date_field')), '20261009');
    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();
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
