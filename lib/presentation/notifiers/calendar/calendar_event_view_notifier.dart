import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_event_view_notifier.g.dart';

class CalendarEventViewState {
  const CalendarEventViewState({
    this.event,
    this.series,
    this.savedLabelName,
    this.isLoading = false,
    this.hasError = false,
  });

  final CalendarEventDto? event;
  final CalendarEventDto? series;
  final String? savedLabelName;
  final bool isLoading;
  final bool hasError;
}

typedef _SavedEvent = ({String? id, DateTime start, CalendarLabelDto? label});

@riverpod
class CalendarEventViewNotifier extends _$CalendarEventViewNotifier {
  int _generation = 0;
  _SavedEvent? _saved;

  @override
  CalendarEventViewState build(
    Object session,
    CalendarEventDto event, {
    CalendarEventDto? series,
  }) {
    ref.onDispose(() => _generation++);
    _saved = null;
    return CalendarEventViewState(event: event, series: series);
  }

  Future<void> refreshAfterSave({
    required String? id,
    required DateTime start,
    CalendarLabelDto? label,
  }) async {
    final saved = (id: id, start: start, label: label);
    _saved = saved;
    await _load(saved);
  }

  Future<void> retry() async {
    final saved = _saved;
    if (state.hasError && saved != null) await _load(saved);
  }

  Future<void> _load(_SavedEvent saved) async {
    final generation = ++_generation;
    state = const CalendarEventViewState(isLoading: true);
    try {
      final id = saved.id;
      final event = id == null
          ? null
          : await ref.read(getCalendarEventByIdProvider)(id);
      if (!ref.mounted || generation != _generation) return;
      if (event == null) {
        state = const CalendarEventViewState();
        return;
      }
      final series = event.recurrenceRule == null ? null : event;
      final occurrence = series == null
          ? event
          : _selectOccurrence(series, saved.start);
      final label = saved.label;
      state = CalendarEventViewState(
        event: occurrence,
        series: occurrence == null ? null : series,
        savedLabelName:
            occurrence != null &&
                label?.groupId == occurrence.groupId &&
                label?.id == occurrence.labelKey
            ? label?.name
            : null,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = const CalendarEventViewState(hasError: true);
    }
  }

  CalendarEventDto? _selectOccurrence(CalendarEventDto series, DateTime start) {
    final expander = ref.read(calendarRecurrenceExpanderProvider);
    final nextDay = start.add(const Duration(days: 1));
    return expander
            .expand(series, start, nextDay)
            .where((event) => event.startDateTime.isAtSameMomentAs(start))
            .firstOrNull ??
        expander.firstOccurrence(series);
  }
}
