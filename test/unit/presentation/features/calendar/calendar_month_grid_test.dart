import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_month_grid.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

Future<void> _pumpGrid(WidgetTester tester, {DateTime? initialDate}) async {
  var state = CalendarState(selectedDate: initialDate ?? DateTime(2026, 10, 1));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CalendarMonthGrid(
            state: state,
            onSelectDay: (date) =>
                setState(() => state = state.copyWith(selectedDate: date)),
            onMoveMonth: (offset) => setState(
              () => state = state.copyWith(
                selectedDate: DateTime(
                  state.month.year,
                  state.month.month + offset,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('指を離す前から現在の月と隣の月が同時に見え短いスワイプは元の月へ戻る', (tester) async {
    await _pumpGrid(tester);
    final grid = find.byKey(const Key('calendar_month_grid'));
    final bounds = tester.getRect(grid);
    final gesture = await tester.startGesture(bounds.center);
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(Offset(-bounds.width * .2, 0));
    await tester.pump();
    final current = find.byKey(const Key('calendar_month_2026_10'));
    final next = find.byKey(const Key('calendar_month_2026_11'));
    expect(next, findsOneWidget);
    expect(tester.getRect(current).overlaps(bounds), isTrue);
    expect(tester.getRect(next).overlaps(bounds), isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar_day_2026_10_2')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final direction in [-1, 1]) {
    for (final (distance, switchesMonth) in [(.35, false), (.45, true)]) {
      testWidgets(
        '${switchesMonth ? '幅の4割を超える低速スワイプで切り替わる' : '幅の4割未満の低速スワイプは戻る'}（$direction）',
        (tester) async {
          await _pumpGrid(tester);
          final grid = find.byKey(const Key('calendar_month_grid'));
          final bounds = tester.getRect(grid);
          final gesture = await tester.startGesture(bounds.center);
          await gesture.moveBy(Offset(20.0 * direction, 0));
          await tester.pump();
          await gesture.moveBy(Offset(bounds.width * distance * direction, 0));
          await tester.pump(const Duration(milliseconds: 400));
          await gesture.up();
          await tester.pumpAndSettle();
          final month = switchesMonth ? (direction == -1 ? 11 : 9) : 10;
          final page = find.byKey(Key('calendar_month_2026_$month'));
          expect(page, findsOneWidget);
          expect(tester.getRect(page).contains(bounds.center), isTrue);
          await tester.tap(find.byKey(Key('calendar_day_2026_${month}_2')));
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final direction in [-1, 1]) {
    for (final (duration, switchesMonth) in [
      (const Duration(milliseconds: 700), true),
      (const Duration(milliseconds: 1100), false),
    ]) {
      testWidgets(
        '${switchesMonth ? '控えめな速度でも月が切り替わる' : 'それより遅い短い横移動は元へ戻る'}（$direction）',
        (tester) async {
          await _pumpGrid(tester);
          final grid = find.byKey(const Key('calendar_month_grid'));
          final bounds = tester.getRect(grid);
          await tester.timedDrag(grid, Offset(80.0 * direction, 0), duration);
          await tester.pumpAndSettle();
          final month = switchesMonth ? (direction == -1 ? 11 : 9) : 10;
          final page = find.byKey(Key('calendar_month_2026_$month'));
          expect(page, findsOneWidget);
          expect(tester.getRect(page).contains(bounds.center), isTrue);
          await tester.tap(find.byKey(Key('calendar_day_2026_${month}_2')));
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('左右へのスワイプ確定後も選択日が表示月と一致する', (tester) async {
    await _pumpGrid(tester);
    final grid = find.byKey(const Key('calendar_month_grid'));
    final bounds = tester.getRect(grid);
    await tester.drag(grid, Offset(-bounds.width * .8, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar_day_2026_11_2')));
    await tester.pump();
    await tester.drag(grid, Offset(bounds.width * .8, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar_day_2026_10_2')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final direction in [-1, 1]) {
    testWidgets('同じフレーム内で切替境界を往復しても指を戻した月を表示する（$direction）', (tester) async {
      await _pumpGrid(tester);
      final bounds = tester.getRect(
        find.byKey(const Key('calendar_month_grid')),
      );
      final gesture = await tester.startGesture(bounds.center);
      await gesture.moveBy(Offset(20.0 * direction, 0));
      await tester.pump();
      await gesture.moveBy(Offset(bounds.width * .49 * direction, 0));
      await tester.pump();
      await gesture.moveBy(Offset(bounds.width * .02 * direction, 0));
      await gesture.moveBy(Offset(-bounds.width * .22 * direction, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pumpAndSettle();
      final current = find.byKey(const Key('calendar_month_2026_10'));
      expect(current, findsOneWidget);
      expect(tester.getRect(current).contains(bounds.center), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (date, direction) in [
    (DateTime(1), 1),
    (DateTime(9999, 12), -1),
  ]) {
    testWidgets('対応期間の端では範囲外の月へスワイプしない（$date）', (tester) async {
      await _pumpGrid(tester, initialDate: date);
      await tester.drag(
        find.byKey(const Key('calendar_month_grid')),
        Offset(600.0 * direction, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(Key('calendar_day_${date.year}_${date.month}_2')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
