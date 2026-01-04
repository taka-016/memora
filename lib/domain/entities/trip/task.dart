import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Task extends Equatable {
  Task({
    this.id,
    required this.tripId,
    required this.orderIndex,
    required this.name,
    required this.isCompleted,
    this.parentTaskId,
    this.dueDate,
    this.memo,
    this.assignedMemberId,
  }) {
    _validate();
  }

  final String? id;
  final String tripId;
  final int orderIndex;
  final String? parentTaskId;
  final String name;
  final bool isCompleted;
  final DateTime? dueDate;
  final String? memo;
  final String? assignedMemberId;

  Task copyWith({
    String? id,
    String? tripId,
    int? orderIndex,
    String? parentTaskId,
    String? name,
    bool? isCompleted,
    DateTime? dueDate,
    String? memo,
    String? assignedMemberId,
  }) {
    return Task(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      orderIndex: orderIndex ?? this.orderIndex,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      memo: memo ?? this.memo,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
    );
  }

  void _validate() {
    if (orderIndex < 0) {
      throw ValidationException('タスクの順序は0以上でなければなりません');
    }
    if (name.trim().isEmpty) {
      throw ValidationException('タスク名は必須です');
    }
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    orderIndex,
    parentTaskId,
    name,
    isCompleted,
    dueDate,
    memo,
    assignedMemberId,
  ];
}
