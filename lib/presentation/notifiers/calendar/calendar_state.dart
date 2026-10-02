import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';

class CalendarState {
  CalendarState({
    required this.selectedDate,
    List<CalendarEventDto> events = const [],
    List<CalendarLabelDto> labels = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.loadError = '',
    this.mutationError = '',
  }) : events = List.unmodifiable(events),
       labels = List.unmodifiable(labels);

  final DateTime selectedDate;
  DateTime get month => DateTime(selectedDate.year, selectedDate.month);
  final List<CalendarEventDto> events;
  final List<CalendarLabelDto> labels;
  final bool isLoading;
  final bool isSaving;
  final String loadError;
  final String mutationError;

  List<CalendarEventDto> eventsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final result = events.where((event) {
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
        return !start.isBefore(first) && !start.isAfter(last);
      }
      final first = event.startDateTime.toLocal();
      final last = event.endDateTime.toLocal();
      return first.isBefore(end) &&
          (last.isAfter(start) || (first == last && !first.isBefore(start)));
    }).toList();
    result.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return result;
  }

  CalendarState copyWith({
    DateTime? selectedDate,
    List<CalendarEventDto>? events,
    List<CalendarLabelDto>? labels,
    bool? isLoading,
    bool? isSaving,
    String? loadError,
    String? mutationError,
  }) => CalendarState(
    selectedDate: selectedDate ?? this.selectedDate,
    events: events ?? this.events,
    labels: labels ?? this.labels,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    loadError: loadError ?? this.loadError,
    mutationError: mutationError ?? this.mutationError,
  );
}
