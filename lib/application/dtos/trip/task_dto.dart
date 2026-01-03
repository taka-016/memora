import 'package:equatable/equatable.dart';

const _copyWithPlaceholder = Object();

class TaskDto extends Equatable {
  const TaskDto({
    required this.id,
    required this.tripId,
    required this.orderIndex,
    required this.name,
    required this.isCompleted,
    this.parentTaskId,
    this.dueDate,
    this.memo,
    this.assignedMemberId,
  });

  final String id;
  final String tripId;
  final int orderIndex;
  final String? parentTaskId;
  final String name;
  final bool isCompleted;
  final DateTime? dueDate;
  final String? memo;
  final String? assignedMemberId;

  TaskDto copyWith({
    String? id,
    String? tripId,
    int? orderIndex,
    Object? parentTaskId = _copyWithPlaceholder,
    String? name,
    bool? isCompleted,
    Object? dueDate = _copyWithPlaceholder,
    Object? memo = _copyWithPlaceholder,
    Object? assignedMemberId = _copyWithPlaceholder,
  }) {
    return TaskDto(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      orderIndex: orderIndex ?? this.orderIndex,
      parentTaskId: identical(parentTaskId, _copyWithPlaceholder)
          ? this.parentTaskId
          : parentTaskId as String?,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: identical(dueDate, _copyWithPlaceholder)
          ? this.dueDate
          : dueDate as DateTime?,
      memo: identical(memo, _copyWithPlaceholder) ? this.memo : memo as String?,
      assignedMemberId: identical(assignedMemberId, _copyWithPlaceholder)
          ? this.assignedMemberId
          : assignedMemberId as String?,
    );
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
