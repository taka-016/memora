import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/services/calendar/calendar_time_zone.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarRecurrenceExpander {
  const CalendarRecurrenceExpander(this.timeZone);
  final CalendarTimeZone timeZone;
  DateTime? seriesEndDateTime(CalendarEventDto event) {
    if (event.recurrenceRule == null) return event.endDateTime;
    final rule = CalendarRecurrenceRule.parse(event.recurrenceRule!);
    final duration = event.duration;
    if (rule.until != null) return rule.until!.add(duration);
    if (rule.count == null) return null;
    final start = event.isAllDay
        ? _date(event.startDateTime)
        : timeZone.local(event.startDateTime, event.timeZone!);
    final day = _date(start);
    final maximumDays = DateTime.utc(10000).difference(day).inDays;
    int countBefore(int days) {
      final before = day.add(Duration(days: days));
      var count = rule.candidateCountBefore(start, before);
      if (!event.isAllDay) {
        count -= timeZone
            .skippedDates(start, before, event.timeZone!)
            .where((date) => rule.matches(date, start))
            .length;
      }
      return count;
    }

    var upper = 1;
    while (upper < maximumDays && countBefore(upper) < rule.count!) {
      upper = upper * 2 < maximumDays ? upper * 2 : maximumDays;
    }
    if (countBefore(upper) < rule.count!) return null;
    var lower = 0;
    while (upper - lower > 1) {
      final middle = (lower + upper) ~/ 2;
      if (countBefore(middle) >= rule.count!) {
        upper = middle;
      } else {
        lower = middle;
      }
    }
    final wall = day.add(Duration(days: upper - 1)).add(start.difference(day));
    final instant = event.isAllDay
        ? wall
        : timeZone.resolve(wall, event.timeZone!);
    return instant?.add(duration);
  }

  DateTime localTime(DateTime instant, String zone) {
    try {
      return timeZone.local(instant, zone);
    } on ValidationException catch (e) {
      throw ApplicationValidationException(e.message);
    }
  }

  DateTime resolveTime(DateTime wall, String zone) {
    try {
      final normalized = DateTime.utc(
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
        wall.second,
        wall.millisecond,
        wall.microsecond,
      );
      final value = timeZone.resolve(normalized, zone);
      if (value == null) throw ValidationException('指定したタイムゾーンにこの時刻は存在しません');
      return value;
    } on ValidationException catch (e) {
      throw ApplicationValidationException(e.message);
    }
  }

  static DateTime _date(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  bool _overlaps(CalendarEventDto event, DateTime from, DateTime to) {
    final start = event.isAllDay
        ? _date(event.startDateTime)
        : event.startDateTime;
    final end = event.isAllDay ? _date(event.endDateTime) : event.endDateTime;
    return start.isBefore(event.isAllDay ? _date(to) : to) &&
        (event.isAllDay ? end.isAfter(_date(from)) : !end.isBefore(from));
  }

  List<CalendarEventDto> expand(
    CalendarEventDto event,
    DateTime from,
    DateTime to,
  ) {
    if (!to.isAfter(from)) throw ValidationException('表示期間が不正です');
    if (event.recurrenceRule == null) {
      return _overlaps(event, from, to) ? [event] : [];
    }
    final rule = CalendarRecurrenceRule.parse(event.recurrenceRule!);
    final start = event.isAllDay
        ? _date(event.startDateTime)
        : timeZone.local(event.startDateTime, event.timeZone!);
    if (!event.isAllDay &&
        timeZone.resolve(start, event.timeZone!) !=
            event.startDateTime.toUtc()) {
      throw ValidationException('夏時間で重複する初回の時刻は早い方を指定してください');
    }
    rule.validateStart(
      event.isAllDay ? start : event.startDateTime,
      event.isAllDay,
      event.recurrenceRule!,
    );
    if (!rule.matches(_date(start), start)) {
      throw ValidationException('開始日は繰り返し条件に一致する必要があります');
    }
    final duration = event.isAllDay
        ? _date(event.endDateTime).difference(start)
        : event.duration;
    DateTime? occurrence(DateTime day) {
      if (!rule.matches(day, start)) return null;
      final wall = day.add(
        Duration(
          hours: start.hour,
          minutes: start.minute,
          seconds: start.second,
          milliseconds: start.millisecond,
          microseconds: start.microsecond,
        ),
      );
      final instant = event.isAllDay
          ? wall
          : timeZone.resolve(wall, event.timeZone!);
      if (instant == null) return null;
      if (rule.until != null &&
          (event.recurrenceRule!.contains(RegExp(r'UNTIL=\d{8}T'))
              ? instant.isAfter(rule.until!)
              : day.isAfter(rule.until!))) {
        return null;
      }
      return instant;
    }

    DateTime originalKey(DateTime value) =>
        event.isAllDay ? _date(value) : value.toUtc();
    int countBefore(DateTime before) {
      final candidates = rule.candidateCountBefore(start, before);
      if (event.isAllDay) return candidates;
      final skipped = timeZone.skippedDates(start, before, event.timeZone!);
      return candidates -
          skipped.where((day) => rule.matches(day, start)).length;
    }

    final overridden = event.overrides
        .map((v) => originalKey(v.originalStartDateTime))
        .toSet();
    final result = <CalendarEventDto>[];
    final endDay = event.isAllDay
        ? _date(to)
        : _date(timeZone.local(to, event.timeZone!))
              .add(const Duration(days: 1));
    var day = _date(start);
    final lower =
        (event.isAllDay
                ? _date(from)
                : _date(timeZone.local(from, event.timeZone!)))
            .subtract(duration)
            .subtract(const Duration(days: 1));
    if (lower.isAfter(day)) day = _date(lower);
    var count = rule.count == null ? 0 : countBefore(day);
    for (final candidate in rule.candidateDays(start, day, endDay)) {
      if (rule.count != null && count >= rule.count!) break;
      final instant = occurrence(candidate);
      if (instant == null) continue;
      count++;
      if (overridden.contains(instant.toUtc())) continue;
      final value = event.copyWith(
        startDateTime: event.isAllDay ? instant : instant.toLocal(),
        endDateTime: event.isAllDay
            ? instant.add(duration)
            : instant.add(duration).toLocal(),
        originalStartDateTime: instant,
      );
      if (_overlaps(value, from, to)) result.add(value);
    }
    result.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return result;
  }
}
