import 'package:memora/core/time/calendar_event_duration.dart';
import 'package:memora/domain/entities/calendar/calendar_notifications.dart';
import 'package:memora/domain/entities/calendar/calendar_label_reference.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

// ignore: constant_identifier_names
const _UNSET_COORDINATE = Object();

class CalendarEvent extends Equatable {
  CalendarEvent({
    this.version,
    this.overridesFingerprint,
    required this.id,
    required this.groupId,
    this.labelId = '',
    this.labelType = 'custom',
    this.memberId = '',
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.url = '',
    this.memo = '',
    this.locationName = '',
    this.latitude,
    this.longitude,
    required this.isAllDay,
    this.recurrenceRule,
    this.timeZone,
    this.overrides = const [],
    this.notificationMinutesBefore = const [],
  }) {
    validateCalendarNotifications(notificationMinutesBefore, isAllDay);
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
  final String? overridesFingerprint;
  final String url;
  final String memo;
  final String locationName;
  final double? latitude;
  final double? longitude;
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
  Duration get duration => calendarEventDuration(startDateTime, endDateTime, isAllDay);
  final bool isAllDay;
  final List<int> notificationMinutesBefore;
  final String? recurrenceRule;
  final String? timeZone;
  final List<CalendarEventOverride> overrides;

  CalendarEvent copyWith({
    int? version,
    String? overridesFingerprint,
    String? id,
    String? groupId,
    String? labelId,
    String? labelType,
    String? memberId,
    String? url,
    String? memo,
    String? locationName,
    Object? latitude = _UNSET_COORDINATE,
    Object? longitude = _UNSET_COORDINATE,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
    List<int>? notificationMinutesBefore,
    String? recurrenceRule,
    String? timeZone,
    List<CalendarEventOverride>? overrides,
  }) {
    return CalendarEvent(
      version: version ?? this.version,
      overridesFingerprint: overridesFingerprint ?? this.overridesFingerprint,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      labelId: labelId ?? this.labelId,
      labelType: labelType ?? this.labelType,
      memberId: memberId ?? this.memberId,
      url: url ?? this.url,
      memo: memo ?? this.memo,
      locationName: locationName ?? this.locationName,
      latitude: identical(latitude, _UNSET_COORDINATE)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _UNSET_COORDINATE)
          ? this.longitude
          : longitude as double?,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isAllDay: isAllDay ?? this.isAllDay,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
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
    url,
    memo,
    locationName,
    latitude,
    longitude,
    title,
    startDateTime,
    endDateTime,
    isAllDay,
    notificationMinutesBefore,
    recurrenceRule,
    timeZone,
    overrides,
  ];
}
