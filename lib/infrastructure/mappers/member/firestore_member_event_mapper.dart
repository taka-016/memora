import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member/member_event.dart';

class FirestoreMemberEventMapper {
  static MemberEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MemberEvent(
      id: doc.id,
      memberId: data?['memberId'] as String? ?? '',
      type: data?['type'] as String? ?? '',
      name: data?['name'] as String?,
      startDate: (data?['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data?['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memo: data?['memo'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(MemberEvent memberEvent) {
    return {
      'memberId': memberEvent.memberId,
      'type': memberEvent.type,
      'name': memberEvent.name,
      'startDate': Timestamp.fromDate(memberEvent.startDate),
      'endDate': Timestamp.fromDate(memberEvent.endDate),
      'memo': memberEvent.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
