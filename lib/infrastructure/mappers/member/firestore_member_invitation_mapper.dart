import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

class FirestoreMemberInvitationMapper {
  static MemberInvitation fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return MemberInvitation(
      id: snapshot.id,
      inviteeId: data['inviteeId'] as String? ?? '',
      inviterId: data['inviterId'] as String? ?? '',
      invitationCode: data['invitationCode'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toFirestore(MemberInvitation memberInvitation) {
    return {
      'inviteeId': memberInvitation.inviteeId,
      'inviterId': memberInvitation.inviterId,
      'invitationCode': memberInvitation.invitationCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
