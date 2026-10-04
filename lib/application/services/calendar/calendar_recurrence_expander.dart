import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/services/calendar/calendar_time_zone.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarRecurrenceExpander {
  const CalendarRecurrenceExpander(this.timeZone);
  final CalendarTimeZone timeZone;
  static DateTime _date(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  bool _overlaps(CalendarEventDto event, DateTime from, DateTime to) {
    final start = event.isAllDay
        ? _date(event.startDateTime)
        : event.startDateTime;
    final end = event.isAllDay ? _date(event.endDateTime) : event.endDateTime;
    return start.isBefore(event.isAllDay ? _date(to) : to) &&
        !end.isBefore(event.isAllDay ? _date(from) : from);
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
        : event.endDateTime.difference(event.startDateTime);
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
    final overridden = event.overrides
        .map((v) => originalKey(v.originalStartDateTime))
        .toSet();
    final result = <CalendarEventDto>[];
    final endDay = event.isAllDay
        ? _date(to)
        : _date(timeZone.local(to, event.timeZone!))
              .add(const Duration(days: 1));
    var day = _date(start);
    // 回数指定のない系列は表示期間に必要な日付からだけ走査する。
    if (rule.count == null) {
      final lower =
          (event.isAllDay
                  ? _date(from)
                  : _date(timeZone.local(from, event.timeZone!)))
              .subtract(duration)
              .subtract(const Duration(days: 1));
      if (lower.isAfter(day)) day = _date(lower);
    }
    var count = 0;
    final originals = <DateTime>{};
    for (; day.isBefore(endDay); day = day.add(const Duration(days: 1))) {
      final instant = occurrence(day);
      if (instant == null) continue;
      count++;
      if (rule.count != null && count > rule.count!) break;
      originals.add(instant.toUtc());
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
    for (final override in event.overrides) {
      final original = originalKey(override.originalStartDateTime);
      if (!originals.contains(original.toUtc())) {
        final wall = event.isAllDay
            ? _date(original)
            : timeZone.local(original, event.timeZone!);
        if (occurrence(_date(wall)) != original.toUtc()) {
          throw ValidationException('上書き対象の回が系列に存在しません');
        }
        if (rule.count != null) {
          var n = 0;
          for (
            var d = _date(start);
            !d.isAfter(_date(wall));
            d = d.add(const Duration(days: 1))
          ) {
            if (occurrence(d) != null) n++;
          }
          if (n > rule.count!) throw ValidationException('上書き対象が指定回数を超えています');
        }
      }
      if (override.isCancelled) continue;
      final value = event.copyWith(
        title: override.title,
        labelId: override.labelId,
        startDateTime: override.startDateTime,
        endDateTime: override.endDateTime,
        isAllDay: override.isAllDay,
        originalStartDateTime: original,
      );
      if (_overlaps(value, from, to)) result.add(value);
    }
    result.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return result;
  }
}
