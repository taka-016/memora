import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarRecurrenceRule {
  CalendarRecurrenceRule._(
    this.frequency,
    this.interval,
    this.count,
    this.until,
    this.weekdays,
    this.monthDay,
    this.ordinal,
  );
  final String frequency;
  final int interval;
  final int? count;
  final DateTime? until;
  final List<int> weekdays;
  final int? monthDay;
  final int? ordinal;
  static const _days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  static Never _invalid() => throw ValidationException('繰り返しルールが不正です');

  factory CalendarRecurrenceRule.parse(String text) {
    final parts = <String, String>{};
    for (final field in text.replaceFirst(RegExp(r'^RRULE:'), '').split(';')) {
      final pair = field.split('=');
      if (pair.length != 2 || pair[1].isEmpty || parts.containsKey(pair[0])) {
        _invalid();
      }
      parts[pair[0]] = pair[1];
    }
    if (parts.keys.any(
      (k) => ![
        'FREQ',
        'INTERVAL',
        'COUNT',
        'UNTIL',
        'BYDAY',
        'BYMONTHDAY',
      ].contains(k),
    )) {
      _invalid();
    }
    final frequency = parts['FREQ'];
    if (!['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'].contains(frequency)) {
      _invalid();
    }
    int positive(String key, int fallback) {
      if (!parts.containsKey(key)) return fallback;
      final value = int.tryParse(parts[key]!);
      if (value == null || value <= 0) _invalid();
      return value;
    }

    final interval = positive('INTERVAL', 1);
    final count = parts.containsKey('COUNT') ? positive('COUNT', 1) : null;
    if (count != null && parts.containsKey('UNTIL')) _invalid();
    DateTime? until;
    if (parts.containsKey('UNTIL')) {
      final value = parts['UNTIL']!;
      if (!RegExp(r'^\d{8}(T\d{6}Z)?$').hasMatch(value)) _invalid();
      until = DateTime.tryParse(value);
      if (until == null ||
          '${until.year.toString().padLeft(4, '0')}${until.month.toString().padLeft(2, '0')}${until.day.toString().padLeft(2, '0')}' !=
              value.substring(0, 8)) {
        _invalid();
      }
      if (value.length == 8) {
        until = DateTime.utc(until.year, until.month, until.day);
      } else if ('${until.hour.toString().padLeft(2, '0')}${until.minute.toString().padLeft(2, '0')}${until.second.toString().padLeft(2, '0')}' !=
          value.substring(9, 15)) {
        _invalid();
      }
    }
    final weekdays = <int>[];
    int? ordinal;
    if (parts.containsKey('BYDAY')) {
      for (final day in parts['BYDAY']!.split(',')) {
        final match = RegExp(r'^(-1|[1-5])?(MO|TU|WE|TH|FR|SA|SU)$')
            .firstMatch(day);
        if (match == null) _invalid();
        final n = match.group(1);
        if (frequency == 'MONTHLY') {
          if (n == null || weekdays.isNotEmpty) _invalid();
          ordinal = int.parse(n);
        } else if (frequency != 'WEEKLY' || n != null) {
          _invalid();
        }
        final weekday = _days.indexOf(match.group(2)!) + 1;
        if (weekdays.contains(weekday)) _invalid();
        weekdays.add(weekday);
      }
    }
    int? monthDay;
    if (parts.containsKey('BYMONTHDAY')) {
      monthDay = positive('BYMONTHDAY', 1);
      if (frequency != 'MONTHLY' || monthDay > 31 || weekdays.isNotEmpty) {
        _invalid();
      }
    }
    return CalendarRecurrenceRule._(
      frequency!,
      interval,
      count,
      until,
      List.unmodifiable(weekdays),
      monthDay,
      ordinal,
    );
  }

  void validateStart(DateTime start, bool allDay, String text) {
    final date = DateTime.utc(start.year, start.month, start.day);
    if (until != null &&
        until!.isBefore(
          allDay || !text.contains(RegExp(r'UNTIL=\d{8}T')) ? date : start,
        )) {
      _invalid();
    }
    final hasUtcUntil = text.contains(RegExp(r'UNTIL=\d{8}T'));
    if (until != null &&
        ((allDay && hasUtcUntil) || (!allDay && !hasUtcUntil))) {
      _invalid();
    }
  }

  int candidateCountBefore(DateTime start, DateTime before) {
    final first = DateTime.utc(start.year, start.month, start.day);
    if (!before.isAfter(first)) return 0;
    if (frequency == 'DAILY') {
      final days = before.difference(first).inDays;
      return days == 0 ? 0 : (days - 1) ~/ interval + 1;
    }
    if (frequency == 'WEEKLY') {
      final weekStart = first.subtract(Duration(days: first.weekday - 1));
      var count = 0;
      for (final weekday in weekdays.isEmpty ? [first.weekday] : weekdays) {
        final candidate = weekStart.add(Duration(days: weekday - 1));
        final days = before.difference(candidate).inDays;
        if (days <= 0) continue;
        count += ((days - 1) ~/ 7) ~/ interval + 1;
        if (candidate.isBefore(first)) count--;
      }
      return count;
    }
    return candidateDays(first, first, before).length;
  }

  // 終了条件と夏時間による回数判定は呼出側が行う。
  Iterable<DateTime> candidateDays(
    DateTime start,
    DateTime from,
    DateTime to,
  ) sync* {
    final first = DateTime.utc(start.year, start.month, start.day);
    final weekStart = first.subtract(Duration(days: first.weekday - 1));
    int elapsedPeriods(DateTime value) => switch (frequency) {
      'DAILY' => value.difference(first).inDays,
      'WEEKLY' => value.difference(weekStart).inDays ~/ 7,
      'MONTHLY' => (value.year - first.year) * 12 + value.month - first.month,
      'YEARLY' => value.year - first.year,
      _ => 0,
    };
    final elapsed = elapsedPeriods(from);
    var period = elapsed > 0 ? elapsed ~/ interval : 0;
    final lastPeriod = elapsedPeriods(to) ~/ interval;
    final selectedWeekdays = weekdays.isEmpty
        ? [first.weekday]
        : (weekdays.toList()..sort());
    while (period <= lastPeriod) {
      final offset = period * interval;
      final base = switch (frequency) {
        'DAILY' => first.add(Duration(days: offset)),
        'WEEKLY' => weekStart.add(Duration(days: offset * 7)),
        'MONTHLY' => DateTime.utc(first.year, first.month + offset),
        'YEARLY' => DateTime.utc(first.year + offset),
        _ => throw StateError('未対応の繰り返し単位です'),
      };
      if (!base.isBefore(to)) break;
      final candidates = <DateTime>[];
      switch (frequency) {
        case 'DAILY':
          candidates.add(base);
        case 'WEEKLY':
          for (final weekday in selectedWeekdays) {
            candidates.add(base.add(Duration(days: weekday - 1)));
          }
        case 'MONTHLY':
          if (ordinal == null) {
            final day = DateTime.utc(
              base.year,
              base.month,
              _monthlyDay(base, first),
            );
            if (day.month == base.month) candidates.add(day);
          } else {
            final anchor = ordinal == -1
                ? DateTime.utc(base.year, base.month + 1, 0)
                : base;
            final shift = ordinal == -1
                ? -((anchor.weekday - weekdays.single + 7) % 7)
                : (weekdays.single - anchor.weekday + 7) % 7 +
                      (ordinal! - 1) * 7;
            final day = anchor.add(Duration(days: shift));
            if (day.month == base.month) candidates.add(day);
          }
        case 'YEARLY':
          final day = DateTime.utc(base.year, first.month, first.day);
          if (day.month == first.month) candidates.add(day);
      }
      for (final day in candidates) {
        if (!day.isBefore(from) && day.isBefore(to) && !day.isBefore(first)) {
          yield day;
        }
      }
      period++;
    }
  }

  bool matches(DateTime day, DateTime start) {
    final days = day
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    if (days < 0) return false;
    switch (frequency) {
      case 'DAILY':
        return days % interval == 0;
      case 'WEEKLY':
        final weeks = (days + start.weekday - 1) ~/ 7;
        return weeks % interval == 0 &&
            (weekdays.isEmpty
                ? day.weekday == start.weekday
                : weekdays.contains(day.weekday));
      case 'MONTHLY':
        final months = (day.year - start.year) * 12 + day.month - start.month;
        if (months % interval != 0) return false;
        if (ordinal == null) return day.day == _monthlyDay(day, start);
        if (day.weekday != weekdays.single) return false;
        return ordinal == -1
            ? DateTime.utc(day.year, day.month, day.day + 7).month != day.month
            : (day.day - 1) ~/ 7 + 1 == ordinal;
      case 'YEARLY':
        return (day.year - start.year) % interval == 0 &&
            day.month == start.month &&
            day.day == start.day;
      default:
        return false;
    }
  }

  int _monthlyDay(DateTime month, DateTime start) {
    final lastDay = DateTime.utc(month.year, month.month + 1, 0).day;
    final requested = monthDay ?? start.day;
    return requested > lastDay ? lastDay : requested;
  }
}
