import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_settings.dart';
import 'package:memora/presentation/features/calendar/calendar_recurrence_dialog.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    CalendarRecurrenceSettings settings,
    void Function(CalendarRecurrenceSettings?) result,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result(
              await showDialog<CalendarRecurrenceSettings>(
                context: context,
                builder: (_) => CalendarRecurrenceCustomDialog(
                  settings: settings,
                  start: DateTime(2026, 10, 2),
                ),
              ),
            ),
            child: const Text('設定'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('設定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('開始日の曜日は選択済みで解除不可、追加曜日は選択できる', (tester) async {
    CalendarRecurrenceSettings? result;
    await open(tester, const CalendarRecurrenceSettings(), (v) => result = v);
    final friday = find.widgetWithText(FilterChip, '金');
    expect(tester.widget<FilterChip>(friday).selected, isTrue);
    expect(tester.widget<FilterChip>(friday).onSelected, isNull);
    await tester.tap(find.widgetWithText(FilterChip, '月'));
    await tester.pump();
    await tester.tap(find.text('決定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(result!.weekdays, [1, 5]);
  });
  testWidgets('毎月は基準日の日付を使い間隔のみ変更できる', (tester) async {
    CalendarRecurrenceSettings? result;
    await open(
      tester,
      const CalendarRecurrenceSettings(
        frequency: 'MONTHLY',
        weekdays: [1],
        ordinal: 2,
      ),
      (v) => result = v,
    );
    expect(find.widgetWithText(TextFormField, '日付'), findsNothing);
    expect(find.text('月の指定方法'), findsNothing);
    expect(find.text('週の指定'), findsNothing);
    expect(find.text('毎月2日'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '間隔'), '3');
    await tester.tap(find.text('決定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(result!.monthDay, 2);
    expect(result!.interval, 3);
    expect(result!.weekdays, isEmpty);
    expect(result!.ordinal, isNull);
  });
  testWidgets('基準日より前の終了条件は決定せず修正を求める', (tester) async {
    CalendarRecurrenceSettings? result;
    await open(
      tester,
      CalendarRecurrenceSettings(
        frequency: 'DAILY',
        until: DateTime(2026, 10, 1),
      ),
      (v) => result = v,
    );
    await tester.tap(find.text('決定'));
    await tester.pump();
    expect(find.text('終了日は開始日以降にしてください'), findsOneWidget);
    expect(result, isNull);
  });
}
