import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_week_layout.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

CalendarEventDto event(
  String id,
  DateTime start,
  DateTime end, {
  bool allDay = true,
}) => CalendarEventDto(
  id: id,
  groupId: 'g',
  labelId: 'l',
  title: '旅行',
  startDateTime: start,
  endDateTime: end,
  isAllDay: allDay,
);
void main() {
  test('複数日終日の帯を週と月の境界で切り各週にタイトルを配置する', () {
    final state = CalendarState(
      selectedDate: DateTime(2026, 10, 1),
      events: [event('trip', DateTime(2026, 9, 30), DateTime(2026, 10, 6))],
    );
    final first = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 9, 27),
      month: DateTime(2026, 10),
    );
    expect(first.entries.single.startColumn, 4);
    expect(first.entries.single.endColumn, 6);
    final next = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 10, 4),
      month: DateTime(2026, 10),
    );
    expect(next.entries.single.startColumn, 0);
    expect(next.entries.single.endColumn, 2);
  });
  test('時刻付きの複数日予定を週と月の境界で切り重複なく帯で表示する', () {
    final state = CalendarState(
      selectedDate: DateTime(2026, 10, 1),
      events: [
        event(
          'timed',
          DateTime(2026, 9, 30, 18),
          DateTime(2026, 10, 6, 10),
          allDay: false,
        ),
      ],
    );
    for (final (weekStart, start, end) in [
      (DateTime(2026, 9, 27), 4, 6),
      (DateTime(2026, 10, 4), 0, 2),
    ]) {
      final layout = CalendarWeekLayout(
        state: state,
        weekStart: weekStart,
        month: DateTime(2026, 10),
      );
      expect(layout.entries.single.startColumn, start);
      expect(layout.entries.single.endColumn, end);
      expect(layout.visibleCounts.sublist(start, end + 1), everyElement(1));
    }
  });
  test('時刻付きの帯は終了が午前0時の場合は前日まで表示する', () {
    final state = CalendarState(
      selectedDate: DateTime(2026, 10, 4),
      events: [
        event(
          'timed',
          DateTime(2026, 10, 4, 18),
          DateTime(2026, 10, 6),
          allDay: false,
        ),
      ],
    );
    final layout = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 10, 4),
      month: DateTime(2026, 10),
    );
    expect(layout.entries.single.startColumn, 0);
    expect(layout.entries.single.endColumn, 1);
    expect(layout.visibleCounts[2], 0);
  });
  test('重複する帯を別段へ配置し同日に時刻付き予定を含め3段まで表示する', () {
    final state = CalendarState(
      selectedDate: DateTime(2026, 10, 4),
      events: [
        event('a', DateTime(2026, 10, 4), DateTime(2026, 10, 6)),
        event('b', DateTime(2026, 10, 5), DateTime(2026, 10, 7)),
        event(
          'c',
          DateTime(2026, 10, 5, 9),
          DateTime(2026, 10, 5, 10),
          allDay: false,
        ),
        event(
          'd',
          DateTime(2026, 10, 5, 11),
          DateTime(2026, 10, 5, 12),
          allDay: false,
        ),
      ],
    );
    final layout = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 10, 4),
      month: DateTime(2026, 10),
    );
    expect(layout.entries.map((entry) => entry.event.id), ['a', 'b', 'c']);
    expect(layout.entries.map((entry) => entry.lane), [0, 1, 2]);
    expect(layout.visibleCounts[1], 3);
  });
}
