import 'package:flutter/material.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_month_grid.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

Future<void> _pumpGrid(
  WidgetTester tester, {
  DateTime? initialDate,
  CalendarDisplaySettings settings = const CalendarDisplaySettings(),
  TargetPlatform platform = TargetPlatform.android,
}) async {
  var state = CalendarState(selectedDate: initialDate ?? DateTime(2026, 10, 1));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CalendarMonthGrid(
            state: state,
            settings: settings,
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
  testWidgets('祝日は日曜と同じ赤色で表示し六曜を設定で切り替える', (tester) async {
    Future<void> pump(bool showRokuyo) => _pumpGrid(tester,
      initialDate: DateTime(2026, 11),
      settings: CalendarDisplaySettings(showRokuyo: showRokuyo),
    );
    Text dayNumber(int day) => tester.widget<Text>(find.descendant(
      of: find.byKey(Key('calendar_day_2026_11_$day')),
      matching: find.text('$day'),
    ));
    await pump(false);
    expect(dayNumber(3).style!.color, dayNumber(1).style!.color);
    expect(dayNumber(3).style!.color, const Color(0xFFD32F2F));
    expect(dayNumber(2).style!.color, isNot(dayNumber(3).style!.color));
    expect(find.text('先勝'), findsNothing);
    await pump(true);
    final cell = find.byKey(const Key('calendar_day_2026_11_8'));
    final rokuyo = find.descendant(of: cell, matching: find.text('先勝'));
    expect(rokuyo, findsOneWidget);
    expect(tester.widget<Text>(rokuyo).style!.fontSize, lessThan(dayNumber(8).style!.fontSize!));
    expect(tester.takeException(), isNull);
    await pump(false);
    expect(find.text('先勝'), findsNothing);
  });

  for (final start in CalendarWeekStart.values) {
    testWidgets('${start.name}始まりでも月初と月末を選択できる', (tester) async {
      await _pumpGrid(tester, initialDate: DateTime(2026, 11),
        settings: CalendarDisplaySettings(weekStart: start, showRokuyo: true));
      final first = find.byKey(const Key('calendar_day_2026_11_1'));
      final second = find.byKey(const Key('calendar_day_2026_11_2'));
      expect(tester.getTopLeft(first).dx < tester.getTopLeft(second).dx,
        start == CalendarWeekStart.sunday);
      await tester.tap(first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('calendar_day_2026_11_30')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

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

  for (final (platform, direction) in [
    (TargetPlatform.android, -1),
    (TargetPlatform.iOS, 1),
  ]) {
    testWidgets('軽いスワイプの少ない移動サンプルでも月と選択日が切り替わる（$platform）', (tester) async {
      await _pumpGrid(tester, platform: platform);
      final grid = find.byKey(const Key('calendar_month_grid'));
      final bounds = tester.getRect(grid);
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
      final month = direction == -1 ? 11 : 9;
      final page = find.byKey(Key('calendar_month_2026_$month'));
      expect(page, findsOneWidget);
      expect(tester.getRect(page).contains(bounds.center), isTrue);
      await tester.tap(find.byKey(Key('calendar_day_2026_${month}_2')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
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
