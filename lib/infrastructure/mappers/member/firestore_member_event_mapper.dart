import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member/member_event.dart';

class FirestoreMemberEventMapper {
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
