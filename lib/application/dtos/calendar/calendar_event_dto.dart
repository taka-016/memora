import 'package:memora/core/time/calendar_event_duration.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:equatable/equatable.dart';

// ignore: constant_identifier_names
const _UNSET_COORDINATE = Object();

class CalendarEventDto extends Equatable {
  const CalendarEventDto({
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
    this.originalStartDateTime,
  });

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
  final DateTime? originalStartDateTime;

  CalendarEventDto copyWith({
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
    DateTime? originalStartDateTime,
  }) {
    return CalendarEventDto(
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
      originalStartDateTime:
          originalStartDateTime ?? this.originalStartDateTime,
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
    originalStartDateTime,
  ];
}
