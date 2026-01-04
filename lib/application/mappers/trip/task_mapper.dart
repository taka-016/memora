import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/domain/entities/trip/task.dart' as entity;

class TaskMapper {
  static TaskDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final dueDateTimestamp = data['dueDate'] as Timestamp?;
    return TaskDto(
      id: doc.id,
      tripId: data['tripId'] as String? ?? '',
      orderIndex: _asInt(data['orderIndex']),
      parentTaskId: data['parentTaskId'] as String?,
      name: data['name'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      dueDate: dueDateTimestamp?.toDate(),
      memo: data['memo'] as String?,
      assignedMemberId: data['assignedMemberId'] as String?,
    );
  }

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

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
