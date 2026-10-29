import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';

class CalendarNotificationRequest {
  const CalendarNotificationRequest({
    required this.key,
    required this.title,
    required this.at,
  });
  final String key;
  final String title;
  final DateTime at;
}

class CalendarNotificationPlanner {
  const CalendarNotificationPlanner(this.expander);
  final CalendarRecurrenceExpander expander;

  List<CalendarNotificationRequest> plan(
    List<CalendarEventDto> events,
    DateTime now,
    CalendarNotificationPreferences settings,
  ) {
    final until = now.add(const Duration(days: 28));
    final result = <CalendarNotificationRequest>[];
    for (final event in events) {
      final offsets = [
        ...event.notificationMinutesBefore,
        ...event.overrides.expand((v) => v.notificationMinutesBefore),
      ];
      if (offsets.isEmpty) continue;
      final max = offsets.reduce((a, b) => a > b ? a : b);
      final occurrences = expander.expand(
        event,
        now.subtract(const Duration(days: 1)),
        until.add(Duration(minutes: max, days: 1)),
      );
      for (final occurrence in occurrences) {
        for (final offset in occurrence.notificationMinutesBefore) {
          final start = occurrence.startDateTime;
          final at = occurrence.isAllDay
              ? DateTime(
                  start.year,
                  start.month,
                  start.day - offset ~/ 1440,
                  settings.allDayMinuteOfDay ~/ 60,
                  settings.allDayMinuteOfDay % 60,
                )
              : start.subtract(Duration(minutes: offset));
          if (at.isBefore(now) || !at.isBefore(until)) continue;
          result.add(
            CalendarNotificationRequest(
              key:
                  '${event.groupId}/${event.id}/${(occurrence.originalStartDateTime ?? start).microsecondsSinceEpoch}/$offset',
              title: occurrence.title,
              at: at,
            ),
          );
        }
      }
    }
    result.sort((a, b) => a.at.compareTo(b.at));
    return result;
  }
}
