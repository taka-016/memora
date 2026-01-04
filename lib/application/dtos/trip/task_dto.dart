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
      parentTaskId: _resolveCopyWithValue<String>(
        parentTaskId,
        this.parentTaskId,
        'parentTaskId',
      ),
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: _resolveCopyWithValue<DateTime>(
        dueDate,
        this.dueDate,
        'dueDate',
      ),
      memo: _resolveCopyWithValue<String>(memo, this.memo, 'memo'),
      assignedMemberId: _resolveCopyWithValue<String>(
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

T? _resolveCopyWithValue<T>(Object? value, T? currentValue, String fieldName) {
  if (identical(value, _copyWithPlaceholder)) {
    return currentValue;
  }

  if (value == null || value is T) {
    return value as T?;
  }

  throw ArgumentError.value(
    value,
    fieldName,
    '型が不正です。${T.toString()}? 型を指定してください。',
  );
}
