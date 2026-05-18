import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class TripEntry extends Equatable {
  TripEntry({
    required this.id,
    required this.groupId,
    required this.year,
    this.name,
    this.startDate,
    this.endDate,
    this.memo,
    List<Pin>? pins,
    List<Task>? tasks,
    List<ItineraryItem>? itineraryItems,
  }) : pins = List.unmodifiable(pins ?? const []),
       tasks = List.unmodifiable(tasks ?? const []),
       itineraryItems = List.unmodifiable(itineraryItems ?? const []) {
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      throw ValidationException('旅行の終了日は開始日以降でなければなりません');
    }
    for (final pin in this.pins) {
      _validatePinPeriod(pin);
    }
    for (final item in this.itineraryItems) {
      _validateItineraryItemPeriod(item);
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
  final int year;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? memo;
  final List<Pin> pins;
  final List<Task> tasks;
  final List<ItineraryItem> itineraryItems;

  TripEntry copyWith({
    String? id,
    String? groupId,
    int? year,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
    List<Pin>? pins,
    List<Task>? tasks,
    List<ItineraryItem>? itineraryItems,
  }) {
    return TripEntry(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
      pins: pins ?? this.pins,
      tasks: tasks ?? this.tasks,
      itineraryItems: itineraryItems ?? this.itineraryItems,
    );
  }

  void _validatePinPeriod(Pin pin) {
    if (startDate != null && endDate != null) {
      if (pin.visitStartDateTime != null) {
        if (pin.visitStartDateTime!.isBefore(startDate!) ||
            pin.visitStartDateTime!.isAfter(endDate!)) {
          throw ValidationException('訪問開始日時は旅行期間内でなければなりません');
        }
      }
      if (pin.visitEndDateTime != null) {
        if (pin.visitEndDateTime!.isBefore(startDate!) ||
            pin.visitEndDateTime!.isAfter(endDate!)) {
          throw ValidationException('訪問終了日時は旅行期間内でなければなりません');
        }
      }
    } else {
      if (pin.visitStartDateTime != null &&
          pin.visitStartDateTime!.year != year) {
        throw ValidationException('訪問開始日時はyearと同じ年にしてください');
      }
      if (pin.visitEndDateTime != null && pin.visitEndDateTime!.year != year) {
        throw ValidationException('訪問終了日時はyearと同じ年にしてください');
      }
    }
  }

  void _validateItineraryItemPeriod(ItineraryItem item) {
    if (startDate != null && endDate != null) {
      final allowedStart = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
      ).subtract(const Duration(days: 2));
      final allowedEndExclusive = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
      ).add(const Duration(days: 3));
      _validateItineraryDateTimeInRange(
        item.startDateTime,
        allowedStart,
        allowedEndExclusive,
      );
      _validateItineraryDateTimeInRange(
        item.endDateTime,
        allowedStart,
        allowedEndExclusive,
      );
    } else {
      if (item.startDateTime != null && item.startDateTime!.year != year) {
        throw ValidationException('旅程項目の開始日時はyearと同じ年にしてください');
      }
      if (item.endDateTime != null && item.endDateTime!.year != year) {
        throw ValidationException('旅程項目の終了日時はyearと同じ年にしてください');
      }
    }
  }

  void _validateItineraryDateTimeInRange(
    DateTime? dateTime,
    DateTime allowedStart,
    DateTime allowedEndExclusive,
  ) {
    if (dateTime == null) {
      return;
    }
    if (dateTime.isBefore(allowedStart) ||
        !dateTime.isBefore(allowedEndExclusive)) {
      throw ValidationException('旅程項目の日時は旅行期間の開始2日前から終了2日後までにしてください');
    }
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    year,
    name,
    startDate,
    endDate,
    memo,
    pins,
    tasks,
    itineraryItems,
  ];
}
