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
  }) {
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

  CalendarEvent copyWith({
    String? id,
    String? groupId,
    String? labelId,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
  }) {
    return CalendarEvent(
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
