import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final (direction, day) in [(-1, 3), (1, 1)]) {
    testWidgets('予定一覧も軽いスワイプで前後の日へ移動し追加対象と選択日を同期する（$direction）', (
      tester,
    ) async {
      final harness = CalendarTestHarness()
        ..savedEvents.add(
          calendarTestEvent('target', '移動先の予定').copyWith(
            startDateTime: DateTime(2026, 10, day, 9),
            endDateTime: DateTime(2026, 10, day, 10),
          ),
        );
      await harness.pump(tester);
      await tester.tap(find.byKey(calendarTestDay2));
      await tester.pump();
      await tester.tap(find.byKey(calendarTestDay2));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      final bounds = tester.getRect(sheet);
      final gesture = await tester.startGesture(bounds.center);
      await gesture.moveBy(
        Offset(20.0 * direction, 0),
        timeStamp: const Duration(milliseconds: 20),
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(
        Offset(40.0 * direction, 0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up(timeStamp: const Duration(milliseconds: 190));
      await tester.pumpAndSettle();
      expect(find.text('2026/10/$dayの予定'), findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('移動先の予定')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('この日に予定を追加'));
      await tester.pumpAndSettle();
      expect(find.text('開始日: 2026/10/$day'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('予定一覧を閉じる'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('calendar_day_2026_10_$day')));
      await tester.pumpAndSettle();
      expect(find.text('2026/10/$dayの予定'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('予定一覧の止めて離す短いスワイプは戻り4割を超えると月末から翌日へ移動する', (tester) async {
    final harness = CalendarTestHarness();
    await harness.pump(tester);
    final lastDay = find.byKey(const Key('calendar_day_2026_10_31'));
    await tester.tapAt(tester.getTopLeft(lastDay) + const Offset(8, 8));
    await tester.pump();
    await tester.tapAt(tester.getTopLeft(lastDay) + const Offset(8, 8));
    await tester.pumpAndSettle();
    final bounds = tester.getRect(find.byType(BottomSheet));
    for (final (distance, title) in [
      (.2, '2026/10/31の予定'),
      (.45, '2026/11/1の予定'),
    ]) {
      final gesture = await tester.startGesture(bounds.center);
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(Offset(-bounds.width * distance, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.byTooltip('予定一覧を閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('2026年11月'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar_day_2026_11_1')));
    await tester.pumpAndSettle();
    expect(find.text('2026/11/1の予定'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
