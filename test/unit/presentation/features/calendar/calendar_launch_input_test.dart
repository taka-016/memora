import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_draft_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_input_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final allDay in [false, true]) {
    testWidgets('外部からの${allDay ? '終日' : '時刻付き'}予定は確認後に新規保存する', (tester) async {
      final harness = CalendarTestHarness();
      await harness.pump(tester);
      final context = tester.element(find.byType(Scaffold).first);
      final start = allDay ? DateTime.utc(2026, 11, 28) : DateTime(2026, 11, 28, 9);
      final end = allDay ? DateTime.utc(2026, 11, 30) : DateTime(2026, 11, 28, 10);
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CalendarEventInputPage(
        date: DateTime(2026, 11, 28),
        initialDraft: CalendarEventDraftDto(
          title: '外部からの予定', memo: '持ち物', locationName: '公園',
          start: start, end: end, isAllDay: allDay,
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.widgetWithText(TextFormField, '外部からの予定'), findsOneWidget);
      expect(find.text('削除'), findsNothing);
      expect(harness.savedEvents, isEmpty);
      await calendarTapVisible(tester, find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final saved = harness.savedEvents.single;
      expect(saved.title, '外部からの予定');
      expect(saved.memo, '持ち物');
      expect(saved.locationName, '公園');
      expect(saved.startDateTime, start);
      expect(saved.endDateTime, end);
      expect(saved.isAllDay, allDay);
    });
  }
}
