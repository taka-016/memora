import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final allDay in [false, true]) {
    for (final days in [-2, 30]) {
      testWidgets('開始日変更で終了日も同じ日数動き期間を維持する（終日$allDay・$days日）', (tester) async {
        final source = calendarTestEvent('e', '複数日の予定').copyWith(
          isAllDay: allDay,
          startDateTime: allDay
              ? DateTime.utc(2026, 10, 2)
              : DateTime(2026, 10, 2, 9),
          endDateTime: allDay
              ? DateTime.utc(2026, 10, 4)
              : DateTime(2026, 10, 4, 23, 59),
        );
        final target = source.startDateTime.add(Duration(days: days));
        final expectedEnd = source.endDateTime.add(Duration(days: days));
        final harness = CalendarTestHarness()..savedEvents.add(source);
        await harness.pump(tester);
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.tap(find.byKey(calendarTestDay2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.widgetWithText(ListTile, '複数日の予定'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('開始日: 2026/10/2'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const Key('date_header')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('date_field')),
          '${target.year}${target.month.toString().padLeft(2, '0')}${target.day.toString().padLeft(2, '0')}',
        );
        await tester.tap(find.text('確定'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(
            '終了日: ${expectedEnd.year}/${expectedEnd.month}/${expectedEnd.day}',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('保存'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final saved =
            verify(harness.update.execute(captureAny)).captured.single
                as CalendarEventDto;
        expect(saved.startDateTime, target);
        expect(saved.endDateTime, expectedEnd);
        expect(
          saved.endDateTime.difference(saved.startDateTime),
          source.endDateTime.difference(source.startDateTime),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
