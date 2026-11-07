import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_week_layout.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

void main() {
  for (final recurring in [false, true]) {
    test('終日予定の終了境界は検索・日別一覧・週表示・期間表示に含めない（繰り返し: $recurring）', () {
      final event = CalendarEventDto(
        id: 'event',
        groupId: 'group',
        labelId: 'label',
        title: '旅行',
        startDateTime: DateTime.utc(2026, 11, 2),
        endDateTime: DateTime.utc(2026, 11, 4),
        isAllDay: true,
        recurrenceRule: recurring ? 'FREQ=WEEKLY;COUNT=2' : null,
      );
      final expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());
      expect(
        expander.expand(event, DateTime(2026, 11, 4), DateTime(2026, 11, 5)),
        isEmpty,
      );
      final values = expander.expand(
        event,
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      );
      final state = CalendarState(
        selectedDate: DateTime(2026, 11),
        events: values,
      );
      expect(state.eventsForDay(DateTime(2026, 11, 3)), hasLength(1));
      expect(state.eventsForDay(DateTime(2026, 11, 4)), isEmpty);
      final layout = CalendarWeekLayout(
        state: state,
        weekStart: DateTime(2026, 11, 1),
        month: DateTime(2026, 11),
      );
      expect(layout.entries.single.startColumn, 1);
      expect(layout.entries.single.endColumn, 2);
      expect(calendarPeriodText(values.single), '2026/11/2 〜 2026/11/3（終日）');
    });
  }
}
