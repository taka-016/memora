import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('タイトルの年月をタップし年と月を回して確定すると指定月へ移動する', (tester) async {
    await CalendarTestHarness().pump(tester, now: DateTime(2026, 10, 31));
    await tester.tap(find.text('2026年10月'));
    await tester.pumpAndSettle();
    expect(find.text('年月を選択'), findsOneWidget);
    final pickers = find.byType(CupertinoPicker);
    expect(pickers, findsNWidgets(2));
    await tester.drag(pickers.at(0), const Offset(0, -40));
    await tester.pumpAndSettle();
    await tester.drag(pickers.at(1), const Offset(0, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移動'));
    await tester.pumpAndSettle();
    expect(find.text('2027年9月'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('calendar_screen'))),
    );
    expect(
      container.read(calendarNotifierProvider('g1')).selectedDate,
      DateTime(2027, 9, 1),
    );
    await tester.tap(find.byTooltip('次の月'));
    await tester.pumpAndSettle();
    expect(find.text('2027年10月'), findsOneWidget);
  });

  testWidgets('選択をキャンセルすると元の年月と選択日を維持する', (tester) async {
    await CalendarTestHarness().pump(tester, now: DateTime(2026, 10, 31));
    await tester.tap(find.text('2026年10月'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('2026年10月'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('calendar_screen'))),
    );
    expect(
      container.read(calendarNotifierProvider('g1')).selectedDate,
      DateTime(2026, 10, 31),
    );
  });
}
