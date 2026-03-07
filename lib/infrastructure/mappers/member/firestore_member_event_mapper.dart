import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/domain/entities/member/member_event.dart';

class FirestoreMemberEventMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static MemberEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberEventDto(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      name: data['name'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      memo: data['memo'] as String?,
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
