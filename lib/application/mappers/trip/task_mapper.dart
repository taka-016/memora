import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/domain/entities/trip/task.dart' as entity;

class TaskMapper {
  static entity.Task toEntity(TaskDto dto) {
    return entity.Task(
      id: dto.id,
      tripId: dto.tripId,
      orderIndex: dto.orderIndex,
      parentTaskId: dto.parentTaskId,
      name: dto.name,
      isCompleted: dto.isCompleted,
      dueDate: dto.dueDate,
      memo: dto.memo,
      assignedMemberId: dto.assignedMemberId,
    );
  }

  static List<entity.Task> toEntityList(List<TaskDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
