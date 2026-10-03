import 'dart:math' as math;

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

class CalendarWeekEntry {
  const CalendarWeekEntry({
    required this.event,
    required this.startColumn,
    required this.endColumn,
    required this.lane,
  });
  final CalendarEventDto event;
  final int startColumn;
  final int endColumn;
  final int lane;
}

class CalendarWeekLayout {
  CalendarWeekLayout({
    required CalendarState state,
    required DateTime weekStart,
    required DateTime month,
  }) {
    final lanes = List.generate(3, (_) => List.filled(7, false));
    final weekDay = _day(weekStart);
    final firstColumn = math.max(
      0,
      _day(DateTime(month.year, month.month)) - weekDay,
    );
    final lastColumn = math.min(
      6,
      _day(DateTime(month.year, month.month + 1, 0)) - weekDay,
    );
    void place(CalendarEventDto event, int start, int end) {
      for (var lane = 0; lane < 3; lane++) {
        if (List.generate(
          end - start + 1,
          (i) => lanes[lane][start + i],
        ).any((occupied) => occupied))
          continue;
        entries.add(
          CalendarWeekEntry(
            event: event,
            startColumn: start,
            endColumn: end,
            lane: lane,
          ),
        );
        for (var column = start; column <= end; column++) {
          lanes[lane][column] = true;
          visibleCounts[column]++;
        }
        break;
      }
    }

    final allDayEvents = state.events.where((event) => event.isAllDay).toList()
      ..sort((a, b) {
        final order = a.startDateTime.compareTo(b.startDateTime);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    for (final event in allDayEvents) {
      final start = math.max(firstColumn, _day(event.startDateTime) - weekDay);
      final end = math.min(lastColumn, _day(event.endDateTime) - weekDay);
      if (start <= end) place(event, start, end);
    }
    for (var column = firstColumn; column <= lastColumn; column++) {
      final date = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + column,
      );
      for (final event
          in state.eventsForDay(date).where((event) => !event.isAllDay)) {
        place(event, column, column);
      }
    }
  }
  final entries = <CalendarWeekEntry>[];
  final visibleCounts = List.filled(7, 0);
  static int _day(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
