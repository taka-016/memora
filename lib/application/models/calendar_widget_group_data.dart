import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';

class CalendarWidgetGroupData {
  const CalendarWidgetGroupData({
    required this.eventsByPeriod,
    required this.labels,
    this.observedAt = const {},
    this.labelsObservedAt = 0,
    this.sourceFiles = const {},
    this.synchronized = false,
  });

  final Map<CalendarEventPeriod, List<CalendarEventDto>> eventsByPeriod;
  final List<CalendarLabelDto>? labels;
  final int labelsObservedAt;
  final Map<CalendarEventPeriod, int> observedAt;
  final Map<String, int> sourceFiles;
  final bool synchronized;
}
