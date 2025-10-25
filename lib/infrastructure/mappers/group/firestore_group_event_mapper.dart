import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_event.dart';

class FirestoreGroupEventMapper {
  static GroupEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return GroupEvent(
      id: doc.id,
      groupId: data?['groupId'] as String? ?? '',
      type: data?['type'] as String? ?? '',
      name: data?['name'] as String?,
      startDate: (data?['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data?['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memo: data?['memo'] as String?,
    );
  }

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
