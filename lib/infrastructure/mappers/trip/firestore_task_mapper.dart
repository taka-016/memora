import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/task.dart';

class FirestoreTaskMapper {
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
}
