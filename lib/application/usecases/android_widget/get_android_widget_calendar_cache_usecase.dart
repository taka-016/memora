import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';

class GetAndroidWidgetCalendarCacheUsecase {
  const GetAndroidWidgetCalendarCacheUsecase({
    required this.events,
    required this.labels,
    required this.groups,
    required this.expander,
    required this.mode,
  });

  final CalendarEventQueryService events;
  final CalendarLabelQueryService labels;
  final GroupQueryService groups;
  final CalendarRecurrenceExpander expander;
  final AppMode mode;

  Future<Map<String, Object?>?> execute(String groupId, DateTime month) async {
    final group = await groups.getGroupWithMembersById(groupId);
    if (group == null) return null;
    DateTime gridStart(DateTime value) {
      final first = DateTime(value.year, value.month);
      return DateTime(first.year, first.month, 1 - first.weekday % 7);
    }

    DateTime gridEnd(DateTime value) {
      final last = DateTime(value.year, value.month + 1, 0);
      return DateTime(last.year, last.month, last.day + 7 - last.weekday % 7);
    }

    final first = DateTime(month.year, month.month);
    final months = [
      for (var offset = -2; offset <= 2; offset++)
        DateTime(first.year, first.month + offset),
    ];
    final from = gridStart(months.first);
    final to = gridEnd(months.last);
    final source = await events.getCalendarEventsByGroupId(groupId);
    final displayLabels = buildCalendarDisplayLabels(
      group,
      await labels.getCalendarLabelsByGroupId(groupId),
      events: source,
    );
    final occurrences = [
      for (final event in source) ...expander.expand(event, from, to),
    ]..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    String dayFormat(DateTime date) => date.toIso8601String().substring(0, 10);
    String timeFormat(DateTime date) =>
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    Map<String, Object?> item(CalendarEventDto event) {
      final label = displayLabels
          .where((v) => v.id == event.labelKey)
          .firstOrNull;
      return {
        'id': event.id,
        'occurrence': (event.originalStartDateTime ?? event.startDateTime)
            .toIso8601String(),
        'title': event.title,
        'isAllDay': event.isAllDay,
        'color': label?.color ?? '#808080',
        'textColor': label?.textColor ?? '#FFFFFF',
        'timeLabel': event.isAllDay
            ? '終日'
            : '${timeFormat(event.startDateTime.toLocal())}–${timeFormat(event.endDateTime.toLocal())}',
      };
    }

    Map<String, Object?> monthData(DateTime value) {
      final start = gridStart(value);
      final end = gridEnd(value);
      final days = <Map<String, Object?>>[];
      for (
        var day = start;
        day.isBefore(end);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        days.add({
          'date': dayFormat(day),
          'events': occurrences
              .where((event) => _onDay(event, day))
              .map(item)
              .toList(),
        });
      }
      return {'month': dayFormat(value), 'days': days};
    }

    final cachedMonths = {
      for (final value in months) dayFormat(value): monthData(value),
    };
    return {
      'sourceMode': mode.name,
      'groupId': groupId,
      'groupName': group.name,
      ...cachedMonths[dayFormat(first)]!,
      'months': cachedMonths,
    };
  }

  bool _onDay(CalendarEventDto event, DateTime day) {
    if (event.isAllDay) {
      final first = DateTime(
        event.startDateTime.year,
        event.startDateTime.month,
        event.startDateTime.day,
      );
      final last = DateTime(
        event.endDateTime.year,
        event.endDateTime.month,
        event.endDateTime.day,
      );
      return !day.isBefore(first) && !day.isAfter(last);
    }
    final first = event.startDateTime.toLocal();
    final last = event.endDateTime.toLocal();
    final end = DateTime(day.year, day.month, day.day + 1);
    return first.isBefore(end) &&
        (last.isAfter(day) || (first == last && !first.isBefore(day)));
  }
}
