import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';

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
    Object? parentTaskId = copyWithPlaceholder,
    String? name,
    bool? isCompleted,
    Object? dueDate = copyWithPlaceholder,
    Object? memo = copyWithPlaceholder,
    Object? assignedMemberId = copyWithPlaceholder,
  }) {
    return TaskDto(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      orderIndex: orderIndex ?? this.orderIndex,
      parentTaskId: resolveCopyWithValue<String>(
        parentTaskId,
        this.parentTaskId,
        'parentTaskId',
      ),
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: resolveCopyWithValue<DateTime>(
        dueDate,
        this.dueDate,
        'dueDate',
      ),
      memo: resolveCopyWithValue<String>(memo, this.memo, 'memo'),
      assignedMemberId: resolveCopyWithValue<String>(
        assignedMemberId,
        this.assignedMemberId,
        'assignedMemberId',
      ),
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
