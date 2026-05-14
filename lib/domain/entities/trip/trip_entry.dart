import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class TripEntry extends Equatable {
  TripEntry({
    required this.id,
    required this.groupId,
    required this.tripYear,
    this.tripName,
    this.tripStartDate,
    this.tripEndDate,
    this.tripMemo,
    List<Pin>? pins,
    List<Task>? tasks,
  }) : pins = List.unmodifiable(pins ?? const []),
       tasks = List.unmodifiable(tasks ?? const []) {
    if (tripStartDate != null &&
        tripEndDate != null &&
        tripEndDate!.isBefore(tripStartDate!)) {
      throw ValidationException('旅行の終了日は開始日以降でなければなりません');
    }
    for (final pin in this.pins) {
      _validatePinPeriod(pin);
    }
    final taskById = {for (final task in this.tasks) task.id: task};
    for (final task in this.tasks) {
      final parentId = task.parentTaskId;
      if (parentId != null) {
        final parentTask = taskById[parentId];
        if (parentTask == null) {
          throw ValidationException('存在しない親タスクが設定されています');
        }
        if (parentTask.isCompleted && !task.isCompleted) {
          throw ValidationException('親タスクが完了の場合は子タスクも完了が必要です');
        }
      }
    }
  }

  final String id;
  final String groupId;
  final int tripYear;
  final String? tripName;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final String? tripMemo;
  final List<Pin> pins;
  final List<Task> tasks;

  TripEntry copyWith({
    String? id,
    String? groupId,
    int? tripYear,
    String? tripName,
    DateTime? tripStartDate,
    DateTime? tripEndDate,
    String? tripMemo,
    List<Pin>? pins,
    List<Task>? tasks,
  }) {
    return TripEntry(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tripYear: tripYear ?? this.tripYear,
      tripName: tripName ?? this.tripName,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripEndDate: tripEndDate ?? this.tripEndDate,
      tripMemo: tripMemo ?? this.tripMemo,
      pins: pins ?? this.pins,
      tasks: tasks ?? this.tasks,
    );
  }

  void _validatePinPeriod(Pin pin) {
    if (_hasTripPeriod) {
      _validatePinWithinTripPeriod(pin);
      return;
    }
    _validatePinWithinTripYear(pin);
  }

  bool get _hasTripPeriod => tripStartDate != null && tripEndDate != null;

  void _validatePinWithinTripPeriod(Pin pin) {
    final tripStartDay = _localDateOnly(tripStartDate!);
    final tripEndDay = _localDateOnly(tripEndDate!);

    _validateDateWithinRange(
      pin.visitStartDate,
      start: tripStartDay,
      end: tripEndDay,
      message: '訪問開始日時は旅行期間内でなければなりません',
    );
    _validateDateWithinRange(
      pin.visitEndDate,
      start: tripStartDay,
      end: tripEndDay,
      message: '訪問終了日時は旅行期間内でなければなりません',
    );
  }

  void _validatePinWithinTripYear(Pin pin) {
    _validateDateYear(
      pin.visitStartDate,
      message: '訪問開始日時はtripYearと同じ年にしてください',
    );
    _validateDateYear(pin.visitEndDate, message: '訪問終了日時はtripYearと同じ年にしてください');
  }

  void _validateDateWithinRange(
    DateTime? value, {
    required DateTime start,
    required DateTime end,
    required String message,
  }) {
    if (value == null) {
      return;
    }

    final localDay = _localDateOnly(value);
    if (localDay.isBefore(start) || localDay.isAfter(end)) {
      throw ValidationException(message);
    }
  }

  void _validateDateYear(DateTime? value, {required String message}) {
    if (value == null) {
      return;
    }

    if (value.year != tripYear) {
      throw ValidationException(message);
    }
  }

  DateTime _localDateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    tripYear,
    tripName,
    tripStartDate,
    tripEndDate,
    tripMemo,
    pins,
    tasks,
  ];
}
