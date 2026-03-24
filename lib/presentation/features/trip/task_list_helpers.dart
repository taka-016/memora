import 'package:memora/application/dtos/trip/task_dto.dart';

List<TaskDto> parentTasks(List<TaskDto> tasks) {
  return tasks.where((task) => task.parentTaskId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
}

List<TaskDto> childrenOfParent(List<TaskDto> tasks, String parentId) {
  return tasks.where((task) => task.parentTaskId == parentId).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
}
