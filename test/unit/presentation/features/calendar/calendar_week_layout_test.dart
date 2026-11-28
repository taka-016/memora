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
  test('最終週は翌月の予定を参照し月をまたぐ帯を重複させない', () {
    final trip = event(
      'trip',
      DateTime.utc(2026, 12, 31),
      DateTime.utc(2027, 1, 3),
    );
    final next = event(
      'next',
      DateTime.utc(2027, 1, 1),
      DateTime.utc(2027, 1, 2),
    );
    final timed = event(
      'timed',
      DateTime(2027, 1, 2, 9),
      DateTime(2027, 1, 2, 10),
      allDay: false,
    );
    final state = CalendarState(
      selectedDate: DateTime(2026, 12),
      events: [trip],
      previewEventsByMonth: {
        DateTime(2027, 1): [trip, next, timed],
      },
    );
    final layout = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 12, 27),
    );
    expect(layout.entries.map((entry) => entry.event.id), [
      'trip',
      'next',
      'timed',
    ]);
    expect(layout.entries.first.startColumn, 4);
    expect(layout.entries.first.endColumn, 6);
    expect(layout.visibleCounts, [0, 0, 0, 0, 1, 2, 2]);
  });

  test('複数日終日の帯を週の境界で切り前月から連続して配置する', () {
    final state = CalendarState(
      selectedDate: DateTime(2026, 10, 1),
      events: [event('trip', DateTime(2026, 9, 30), DateTime(2026, 10, 7))],
    );
    final first = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 9, 27),
    );
    expect(first.entries.single.startColumn, 3);
    expect(first.entries.single.endColumn, 6);
    final next = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 10, 4),
    );
    expect(next.entries.single.startColumn, 0);
    expect(next.entries.single.endColumn, 2);
  });
  test('時刻付きの複数日予定を週の境界で切り前月から重複なく帯で表示する', () {
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
      (DateTime(2026, 9, 27), 3, 6),
      (DateTime(2026, 10, 4), 0, 2),
    ]) {
      final layout = CalendarWeekLayout(state: state, weekStart: weekStart);
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
    );
    expect(layout.entries.single.startColumn, 0);
    expect(layout.entries.single.endColumn, 1);
    expect(layout.visibleCounts[2], 0);
  });
  test('祝日の先頭行を避けて複数日の帯を配置し非表示件数は予定だけを数える', () {
    final state = CalendarState(
      selectedDate: DateTime(2026, 11),
      events: [
        event('旅行', DateTime.utc(2026, 11, 2), DateTime.utc(2026, 11, 4)),
      ],
    );
    CalendarWeekLayout layout(int lines) => CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 11),
      maxVisibleEvents: lines,
      isHoliday: (date) => date.day == 3,
    );
    final visible = layout(2);
    expect(visible.entries.single.lane, 1);
    expect(visible.entries.single.startColumn, 1);
    expect(visible.entries.single.endColumn, 2);
    expect(visible.visibleCounts[2], 1);
    final hidden = layout(1);
    expect(hidden.entries, isEmpty);
    expect(
      state.eventsForDay(DateTime(2026, 11, 3)).length -
          hidden.visibleCounts[2],
      1,
    );
  });

  test('重複する帯を別段へ配置し同日に時刻付き予定を含め5段まで表示する', () {
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
        for (final id in ['d', 'e', 'f'])
          event(
            id,
            DateTime(2026, 10, 5, 11),
            DateTime(2026, 10, 5, 12),
            allDay: false,
          ),
      ],
    );
    final layout = CalendarWeekLayout(
      state: state,
      weekStart: DateTime(2026, 10, 4),
    );
    expect(layout.entries.map((entry) => entry.event.id), [
      'a',
      'b',
      'c',
      'd',
      'e',
    ]);
    expect(layout.entries.map((entry) => entry.lane), [0, 1, 2, 3, 4]);
    expect(layout.visibleCounts[1], 5);
  });
}
