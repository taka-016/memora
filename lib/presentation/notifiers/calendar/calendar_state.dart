import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';

class CalendarState {
  CalendarState({
    required this.selectedDate,
    this.group,
    this.groupLoadError = '',
    List<CalendarEventDto> events = const [],
    Map<DateTime, List<CalendarEventDto>> previewEventsByMonth = const {},
    List<CalendarLabelDto> labels = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.loadError = '',
    this.eventLoadError = '',
    this.labelLoadError = '',
    this.hasLoadedEvents = false,
    this.hasLoadedLabels = false,
    this.isWatching = false,
    this.mutationError = '',
  }) : events = List.unmodifiable(events),
       previewEventsByMonth = Map.unmodifiable({
         for (final entry in previewEventsByMonth.entries)
           entry.key: List<CalendarEventDto>.unmodifiable(entry.value),
       }),
       labels = List.unmodifiable(labels);

  final GroupDto? group;
  final String groupLoadError;
  List<CalendarLabelDto> get displayLabels => group == null
      ? labels
      : buildCalendarDisplayLabels(
          group!,
          labels,
          events: [
            ...events,
            for (final preview in previewEventsByMonth.values) ...preview,
          ],
        );
  final DateTime selectedDate;
  DateTime get month => DateTime(selectedDate.year, selectedDate.month);
  final List<CalendarEventDto> events;
  final Map<DateTime, List<CalendarEventDto>> previewEventsByMonth;
  final List<CalendarLabelDto> labels;
  final bool isLoading;
  final bool isSaving;
  final String loadError;
  final String eventLoadError;
  final String labelLoadError;
  final bool hasLoadedEvents;
  final bool hasLoadedLabels;
  final bool isWatching;
  final String mutationError;

  List<CalendarEventDto> eventsForMonth(DateTime day) =>
      previewEventsByMonth[DateTime(day.year, day.month)] ?? events;

  List<CalendarEventDto> eventsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final result = eventsForMonth(day).where((event) {
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
        return !start.isBefore(first) && start.isBefore(last);
      }
      final first = event.startDateTime.toLocal();
      final last = event.endDateTime.toLocal();
      return first.isBefore(end) &&
          (last.isAfter(start) || (first == last && !first.isBefore(start)));
    }).toList();
    result.sort((a, b) {
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      return a.startDateTime.compareTo(b.startDateTime);
    });
    return result;
  }

  CalendarState copyWith({
    DateTime? selectedDate,
    GroupDto? group,
    String? groupLoadError,
    List<CalendarEventDto>? events,
    Map<DateTime, List<CalendarEventDto>>? previewEventsByMonth,
    List<CalendarLabelDto>? labels,
    bool? isLoading,
    bool? isSaving,
    String? loadError,
    String? eventLoadError,
    String? labelLoadError,
    bool? hasLoadedEvents,
    bool? hasLoadedLabels,
    bool? isWatching,
    String? mutationError,
  }) => CalendarState(
    selectedDate: selectedDate ?? this.selectedDate,
    group: group ?? this.group,
    groupLoadError: groupLoadError ?? this.groupLoadError,
    events: events ?? this.events,
    previewEventsByMonth: previewEventsByMonth ?? this.previewEventsByMonth,
    labels: labels ?? this.labels,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    loadError: loadError ?? this.loadError,
    eventLoadError: eventLoadError ?? this.eventLoadError,
    labelLoadError: labelLoadError ?? this.labelLoadError,
    hasLoadedEvents: hasLoadedEvents ?? this.hasLoadedEvents,
    hasLoadedLabels: hasLoadedLabels ?? this.hasLoadedLabels,
    isWatching: isWatching ?? this.isWatching,
    mutationError: mutationError ?? this.mutationError,
  );
}
