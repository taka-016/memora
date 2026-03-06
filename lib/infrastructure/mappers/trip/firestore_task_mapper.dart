import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/domain/entities/trip/task.dart';

class FirestoreTaskMapper {
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

  static Map<String, dynamic> toFirestore(Task task) {
    final data = <String, dynamic>{
      'tripId': task.tripId,
      'orderIndex': task.orderIndex,
      'parentTaskId': task.parentTaskId,
      'name': task.name,
      'isCompleted': task.isCompleted,
      'memo': task.memo,
      'assignedMemberId': task.assignedMemberId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    data['dueDate'] = task.dueDate != null
        ? Timestamp.fromDate(task.dueDate!)
        : null;

    return data;
  }

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
