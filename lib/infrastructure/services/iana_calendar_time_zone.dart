import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'package:memora/domain/services/calendar/calendar_time_zone.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class IanaCalendarTimeZone implements CalendarTimeZone {
  IanaCalendarTimeZone() {
    if (!_initialized) {
      data.initializeTimeZones();
      _initialized = true;
    }
  }
  static bool _initialized = false;
  tz.Location _location(String zone) {
    try {
      return tz.getLocation(zone);
    } catch (_) {
      throw ValidationException('未対応のタイムゾーンです: $zone');
    }
  }

  @override
  List<DateTime> skippedDates(
    DateTime wallStart,
    DateTime before,
    String zone,
  ) {
    final location = _location(zone);
    final skipped = <DateTime>{};
    final time = wallStart.difference(
      DateTime.utc(wallStart.year, wallStart.month, wallStart.day),
    );
    for (final transition in location.transitionAt) {
      final oldOffset = location.timeZone(transition - 1).offset;
      final newOffset = location.timeZone(transition).offset;
      if (newOffset <= oldOffset) continue;
      final instant = DateTime.fromMillisecondsSinceEpoch(
        transition,
        isUtc: true,
      );
      final gapStart = instant.add(oldOffset);
      final gapEnd = instant.add(newOffset);
      for (
        var day = DateTime.utc(gapStart.year, gapStart.month, gapStart.day);
        day.isBefore(gapEnd) && day.isBefore(before);
        day = day.add(const Duration(days: 1))
      ) {
        final wall = day.add(time);
        if (!wall.isBefore(wallStart) &&
            !wall.isBefore(gapStart) &&
            wall.isBefore(gapEnd) &&
            resolve(wall, zone) == null) {
          skipped.add(day);
        }
      }
    }
    return skipped.toList()..sort();
  }

  @override
  DateTime local(DateTime instant, String zone) {
    final value = tz.TZDateTime.from(instant, _location(zone));
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  @override
  DateTime? resolve(DateTime wallTime, String zone) {
    final location = _location(zone);
    final matches = <DateTime>[];
    for (final offset in location.zones.map((z) => z.offset).toSet()) {
      final instant = wallTime.subtract(offset);
      if (local(instant, zone) == wallTime) matches.add(instant);
    }
    matches.sort();
    return matches.isEmpty ? null : matches.first;
  }
}
