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
  });

  final String id;
  final String groupId;
  final String labelId;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;

  CalendarEventDto copyWith({
    String? id,
    String? groupId,
    String? labelId,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
  }) {
    return CalendarEventDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      labelId: labelId ?? this.labelId,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isAllDay: isAllDay ?? this.isAllDay,
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
  ];
}
