import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

class FirestoreMemberInvitationMapper {
  static Map<String, dynamic> toFirestore(MemberInvitation memberInvitation) {
    return {
      'inviteeId': memberInvitation.inviteeId,
      'inviterId': memberInvitation.inviterId,
      'invitationCode': memberInvitation.invitationCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
