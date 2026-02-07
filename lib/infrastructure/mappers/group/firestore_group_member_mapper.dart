import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group_member.dart';

class FirestoreGroupMemberMapper {
  static Map<String, dynamic> toFirestore(GroupMember groupMember) {
    return {
      'groupId': groupMember.groupId,
      'memberId': groupMember.memberId,
      'isAdministrator': groupMember.isAdministrator,
      'orderIndex': groupMember.orderIndex,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
