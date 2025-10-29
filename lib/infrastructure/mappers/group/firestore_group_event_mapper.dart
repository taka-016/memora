import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_event.dart';

class FirestoreGroupEventMapper {
  static Map<String, dynamic> toFirestore(GroupEvent groupEvent) {
    return {
      'groupId': groupEvent.groupId,
      'type': groupEvent.type,
      'name': groupEvent.name,
      'startDate': Timestamp.fromDate(groupEvent.startDate),
      'endDate': Timestamp.fromDate(groupEvent.endDate),
      'memo': groupEvent.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
