import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreMemberInvitationMapper {
  static MemberInvitationDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberInvitationDto(
      id: doc.id,
      inviteeId: data['inviteeId'] as String? ?? '',
      inviterId: data['inviterId'] as String? ?? '',
      invitationCode: data['invitationCode'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toCreateFirestore(
    MemberInvitation memberInvitation,
  ) {
    return {
      'inviteeId': memberInvitation.inviteeId,
      'inviterId': memberInvitation.inviterId,
      'invitationCode': memberInvitation.invitationCode,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(
    MemberInvitation memberInvitation,
  ) {
    return {
      'inviteeId': memberInvitation.inviteeId,
      'inviterId': memberInvitation.inviterId,
      'invitationCode': memberInvitation.invitationCode,
      ...FirestoreWriteMetadata.forUpdate(),
    };
  }
}
