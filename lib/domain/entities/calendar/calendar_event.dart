import 'package:memora/domain/entities/calendar/calendar_label_reference.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarEvent extends Equatable {
  CalendarEvent({
    this.version,
    required this.id,
    required this.groupId,
    this.labelId = '',
    this.labelType = 'custom',
    this.memberId = '',
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
    if (!validCalendarLabelReference(labelType, memberId, labelId)) {
      throw ValidationException('色ラベルは必須です');
    }
    if (title.trim().isEmpty) {
      throw ValidationException('予定のタイトルは必須です');
    }
    if (endDateTime.isBefore(startDateTime)) {
      throw ValidationException('予定の終了日時は開始日時以降でなければなりません');
    }
  }

  final int? version;
  final String id;
  final String groupId;
  final String labelId;
  final String labelType;
  final String memberId;

  String get labelKey => switch (labelType) {
    'group' => 'group:',
    'member' => 'member:$memberId',
    _ => labelId,
  };
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String? recurrenceRule;
  final String? timeZone;
  final List<CalendarEventOverride> overrides;

  CalendarEvent copyWith({
    int? version,
    String? id,
    String? groupId,
    String? labelId,
    String? labelType,
    String? memberId,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
    String? recurrenceRule,
    String? timeZone,
    List<CalendarEventOverride>? overrides,
  }) {
    return CalendarEvent(
      version: version ?? this.version,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      labelId: labelId ?? this.labelId,
      labelType: labelType ?? this.labelType,
      memberId: memberId ?? this.memberId,
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
    version,
    id,
    groupId,
    labelId,
    labelType,
    memberId,
    title,
    startDateTime,
    endDateTime,
    isAllDay,
    recurrenceRule,
    timeZone,
    overrides,
  ];
}
