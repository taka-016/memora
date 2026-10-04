import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarEventOverride extends Equatable {
  CalendarEventOverride({
    required this.originalStartDateTime,
    required this.isCancelled,
    this.title,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay,
    this.labelId,
  }) {
    if (!isCancelled &&
        (title == null ||
            title!.trim().isEmpty ||
            startDateTime == null ||
            endDateTime == null ||
            isAllDay == null ||
            labelId == null ||
            labelId!.trim().isEmpty ||
            endDateTime!.isBefore(startDateTime!))) {
      throw ValidationException('個別回の変更にはタイトル・期間・終日区分・色ラベルが必要です');
    }
  }
  final DateTime originalStartDateTime;
  final bool isCancelled;
  final String? title;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool? isAllDay;
  final String? labelId;
  @override
  List<Object?> get props => [
    originalStartDateTime.toUtc(),
    isCancelled,
    title,
    startDateTime,
    endDateTime,
    isAllDay,
    labelId,
  ];
}
