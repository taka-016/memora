import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarEvent extends Equatable {
  CalendarEvent({
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
  }) {
    if (recurrenceRule != null) {
      CalendarRecurrenceRule.parse(recurrenceRule!)
          .validateStart(startDateTime, isAllDay, recurrenceRule!);
      if (!isAllDay && (timeZone == null || timeZone!.trim().isEmpty)) {
        throw ValidationException('系列のタイムゾーンは必須です');
      }
    } else if (overrides.isNotEmpty || timeZone != null) {
      throw ValidationException('個別回の上書きは繰り返し予定にのみ指定できます');
    }
    if (overrides
            .map(
              (v) => isAllDay
                  ? DateTime.utc(
                      v.originalStartDateTime.year,
                      v.originalStartDateTime.month,
                      v.originalStartDateTime.day,
                    )
                  : v.originalStartDateTime.toUtc(),
            )
            .toSet()
            .length !=
        overrides.length) {
      throw ValidationException('同じ個別回を重複指定できません');
    }
    if (groupId.trim().isEmpty) {
      throw ValidationException('グループは必須です');
    }
    if (labelId.trim().isEmpty) {
      throw ValidationException('色ラベルは必須です');
    }
    if (title.trim().isEmpty) {
      throw ValidationException('予定のタイトルは必須です');
    }
    if (endDateTime.isBefore(startDateTime)) {
      throw ValidationException('予定の終了日時は開始日時以降でなければなりません');
    }
  }

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

  CalendarEvent copyWith({
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
  }) {
    return CalendarEvent(
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
  ];
}
