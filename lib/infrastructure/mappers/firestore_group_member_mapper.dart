import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group_member.dart';

class FirestoreGroupMemberMapper {
  static GroupMember fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return GroupMember(
      groupId: data?['groupId'] as String? ?? '',
      memberId: data?['memberId'] as String? ?? '',
      isAdministrator: data?['isAdministrator'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> toFirestore(GroupMember groupMember) {
    return {
      'groupId': groupMember.groupId,
      'memberId': groupMember.memberId,
      'isAdministrator': groupMember.isAdministrator,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
