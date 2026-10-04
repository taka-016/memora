import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:equatable/equatable.dart';

class CalendarEventDto extends Equatable {
  const CalendarEventDto({
    required this.id,
    required this.groupId,
    required this.labelId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.isAllDay,
    this.recurrenceRule,
    this.timeZone,
    this.overrides = const [],
    this.originalStartDateTime,
  });

  final String id;
  final String groupId;
  final String labelId;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String? recurrenceRule;
  final String? timeZone;
  final List<CalendarEventOverride> overrides;
  final DateTime? originalStartDateTime;

  CalendarEventDto copyWith({
    String? id,
    String? groupId,
    String? labelId,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
    String? recurrenceRule,
    String? timeZone,
    List<CalendarEventOverride>? overrides,
    DateTime? originalStartDateTime,
  }) {
    return CalendarEventDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      labelId: labelId ?? this.labelId,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      timeZone: timeZone ?? this.timeZone,
      overrides: overrides ?? this.overrides,
      originalStartDateTime:
          originalStartDateTime ?? this.originalStartDateTime,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    labelId,
    title,
    startDateTime,
    endDateTime,
    isAllDay,
    recurrenceRule,
    timeZone,
    overrides,
    originalStartDateTime,
  ];
}
