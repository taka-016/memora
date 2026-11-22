import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/services/calendar/japanese_calendar.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/models/calendar_widget_group_data.dart';
import 'package:memora/application/services/current_user_service.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/usecases/android_widget/get_calendar_widget_selection_usecase.dart';

class GetAndroidWidgetCalendarCacheUsecase {
  const GetAndroidWidgetCalendarCacheUsecase({
    required this.events,
    required this.labels,
    required this.expander,
    required this.mode,
    this.currentUser,
    this.loadSharedGroup,
  });

  final CalendarEventQueryService events;
  final CalendarLabelQueryService labels;
  final CalendarRecurrenceExpander expander;
  final AppMode mode;
  final CurrentUserService? currentUser;
  final Future<CalendarWidgetGroupData> Function(
    String ownerId,
    String groupId,
    List<CalendarEventPeriod> periods, {
    required bool force,
  })?
  loadSharedGroup;

  Future<Map<String, Object?>?> execute(
    List<GroupDto> groups,
    DateTime month, {
    String? ownerId,
    bool force = false,
  }) async {
    DateTime gridStart(DateTime value) {
      final first = DateTime(value.year, value.month);
      return DateTime(first.year, first.month, 1 - 6);
    }

    DateTime gridEnd(DateTime value) {
      final last = DateTime(value.year, value.month + 1, 0);
      return DateTime(last.year, last.month, last.day + 7);
    }

    final first = DateTime(month.year, month.month);
    final months = [
      for (var offset = -1; offset <= 1; offset++)
        DateTime(first.year, first.month + offset),
    ];
    final from = gridStart(months.first);
    final to = gridEnd(months.last);
    final period = CalendarEventPeriod(from: from, to: to);
    final load = loadSharedGroup;
    final useShared = load != null && ownerId != null;
    final quarters = {
      for (final value in months)
        if (value.year >= 1 && value.year <= 9999)
          CalendarEventPeriod.forQuarter(value),
    }.toList();
    final occurrencesByPeriod = <CalendarEventPeriod, List<CalendarEventDto>>{};
    final displayLabels = <CalendarLabelDto>[];
    final sourceFiles = <String, int>{};
    final observedAt = <CalendarEventPeriod, int>{};
    var synchronized = !useShared || (groups.isEmpty && force);
    final visibleIds = <String>[];
    final sortedGroups = groups.toList()..sort((a, b) => a.id.compareTo(b.id));
    for (final group in sortedGroups) {
      final groupId = group.id;
      visibleIds.add(groupId);
      final data = useShared
          ? await load(ownerId, groupId, quarters, force: force)
          : CalendarWidgetGroupData(
              eventsByPeriod: {
                period: await events.getCalendarEventsByGroupId(
                  groupId,
                  period: period,
                ),
              },
              labels: await labels.getCalendarLabelsByGroupId(groupId),
            );
      sourceFiles.addAll(data.sourceFiles);
      synchronized |= data.synchronized;
      for (final entry in data.observedAt.entries) {
        final current = observedAt[entry.key];
        if (current == null || entry.value < current) {
          observedAt[entry.key] = entry.value;
        }
      }
      displayLabels.addAll(
        buildCalendarDisplayLabels(
          group,
          data.labels ?? const [],
          events: data.eventsByPeriod.values
              .expand((events) => events)
              .toList(),
        ),
      );
      for (final MapEntry(key: bounds, value: source)
          in data.eventsByPeriod.entries) {
        (occurrencesByPeriod[bounds] ??= []).addAll(
          source.expand(
            (event) => expander.expand(event, bounds.from, bounds.to),
          ),
        );
      }
    }
    for (final occurrences in occurrencesByPeriod.values) {
      occurrences.sort((a, b) {
        if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
        return a.startDateTime.compareTo(b.startDateTime);
      });
    }
    Iterable<CalendarEventDto> eventsOn(DateTime day) {
      final key = useShared ? CalendarEventPeriod.forQuarter(day) : period;
      return (occurrencesByPeriod[key] ?? const []).where(
        (event) => _onDay(event, day),
      );
    }

    String dayFormat(DateTime date) => date.toIso8601String().substring(0, 10);
    String timeFormat(DateTime date) =>
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    Map<String, Object?> item(CalendarEventDto event) {
      final label = displayLabels
          .where((v) => v.id == event.labelKey && v.groupId == event.groupId)
          .firstOrNull;
      return {
        'id': event.id,
        'groupId': event.groupId,
        'startMillis': event.startDateTime.millisecondsSinceEpoch,
        'occurrence': (event.originalStartDateTime ?? event.startDateTime)
            .toIso8601String(),
        'title': event.title,
        'isAllDay': event.isAllDay,
        'isMultiDay': _isMultiDay(event),
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
          'holidayName': JapaneseCalendar.holidayName(day),
          'rokuyo': JapaneseCalendar.rokuyo(day),
          'events': eventsOn(day).map(item).toList(),
        });
      }
      final observed = observedAt[CalendarEventPeriod.forQuarter(value)] ?? 0;
      return {
        'month': dayFormat(value),
        'days': days,
        if (useShared) 'sourceFiles': sourceFiles,
        if (observed > 0)
          'lastUpdatedAt': DateTime.fromMicrosecondsSinceEpoch(observed)
              .toIso8601String(),
      };
    }

    final cachedMonths = {
      for (final value in months) dayFormat(value): monthData(value),
    };
    final deviceOwner = mode == AppMode.online
        ? (await currentUser?.getCurrentUser())?.id
        : null;
    return {
      'cacheScope': CalendarWidgetSelection.encodeScope(
        mode,
        ownerId ?? deviceOwner,
        visibleIds,
      ),
      'visibleGroupIds': visibleIds,
      'sourceMode': mode.name,
      if (useShared) 'synchronized': synchronized,
      'deviceCalendarOwnerId': deviceOwner,
      ...cachedMonths[dayFormat(first)]!,
      'months': cachedMonths,
    };
  }

  bool _isMultiDay(CalendarEventDto event) {
    final start = event.isAllDay
        ? event.startDateTime
        : event.startDateTime.toLocal();
    final end = event.isAllDay
        ? event.endDateTime
        : event.endDateTime.toLocal();
    final last = end.isAfter(start)
        ? end.subtract(const Duration(microseconds: 1))
        : end;
    return start.year != last.year ||
        start.month != last.month ||
        start.day != last.day;
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
      return !day.isBefore(first) && day.isBefore(last);
    }
    final first = event.startDateTime.toLocal();
    final last = event.endDateTime.toLocal();
    final end = DateTime(day.year, day.month, day.day + 1);
    return first.isBefore(end) &&
        (last.isAfter(day) || (first == last && !first.isBefore(day)));
  }
}
