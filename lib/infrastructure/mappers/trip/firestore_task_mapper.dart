import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreTaskMapper {
  static TaskDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TaskDto(
      id: doc.id,
      tripId: data['tripId'] as String? ?? '',
      orderIndex: FirestoreMapperValueParser.asInt(data['orderIndex']),
      parentTaskId: data['parentTaskId'] as String?,
      name: data['name'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      dueDate: FirestoreMapperValueParser.asDateTime(data['dueDate']),
      memo: data['memo'] as String?,
      assignedMemberId: data['assignedMemberId'] as String?,
    );
  }

  static Map<String, dynamic> toCreateFirestore(Task task) {
    final data = <String, dynamic>{
      'tripId': task.tripId,
      'orderIndex': task.orderIndex,
      'parentTaskId': task.parentTaskId,
      'name': task.name,
      'isCompleted': task.isCompleted,
      'memo': task.memo,
      'assignedMemberId': task.assignedMemberId,
      ...FirestoreWriteMetadata.forCreate(),
    };

    data['dueDate'] = task.dueDate != null
        ? Timestamp.fromDate(task.dueDate!)
        : null;

    return data;
  }

  static Map<String, dynamic> toUpdateFirestore(Task task) {
    final data = <String, dynamic>{
      'tripId': task.tripId,
      'orderIndex': task.orderIndex,
      'parentTaskId': task.parentTaskId,
      'name': task.name,
      'isCompleted': task.isCompleted,
      'memo': task.memo,
      'assignedMemberId': task.assignedMemberId,
      ...FirestoreWriteMetadata.forUpdate(),
    };

    data['dueDate'] = task.dueDate != null
        ? Timestamp.fromDate(task.dueDate!)
        : null;

    return data;
  }
}
