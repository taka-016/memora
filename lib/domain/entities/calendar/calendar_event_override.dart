import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarEventOverride extends Equatable {
  CalendarEventOverride({
    required this.originalStartDateTime,
    this.isCancelled = true,
  }) {
    if (!isCancelled) throw ValidationException('個別変更は通常予定として保存してください');
  }
  final DateTime originalStartDateTime;
  final bool isCancelled;
  @override
  List<Object?> get props => [originalStartDateTime.toUtc(), isCancelled];
}
