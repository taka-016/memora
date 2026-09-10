import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';

class SqliteTaskMapper {
  static TaskDto fromRow(Map<String, Object?> row) => TaskDto(
    id: row['id'] as String,
    tripId: row['trip_id'] as String,
    orderIndex: row['order_index'] as int,
    parentTaskId: row['parent_task_id'] as String?,
    name: row['name'] as String,
    isCompleted: row['is_completed'] == 1,
    dueDate: SqliteValues.date(row['due_date']),
    memo: row['memo'] as String?,
    assignedMemberId: row['assigned_member_id'] as String?,
  );
  static Map<String, Object?> toRow(Task value) => {
    'id': value.id,
    'trip_id': value.tripId,
    'order_index': value.orderIndex,
    'parent_task_id': value.parentTaskId,
    'name': value.name,
    'is_completed': value.isCompleted ? 1 : 0,
    'due_date': value.dueDate?.microsecondsSinceEpoch,
    'memo': value.memo,
    'assigned_member_id': value.assignedMemberId,
  };
}
