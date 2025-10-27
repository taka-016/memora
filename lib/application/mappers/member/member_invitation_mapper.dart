import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

class MemberInvitationMapper {
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

  static MemberInvitation toEntity(MemberInvitationDto dto) {
    return MemberInvitation(
      id: dto.id,
      inviteeId: dto.inviteeId,
      inviterId: dto.inviterId,
      invitationCode: dto.invitationCode,
    );
  }

  static MemberInvitationDto toDto(MemberInvitation entity) {
    return MemberInvitationDto(
      id: entity.id,
      inviteeId: entity.inviteeId,
      inviterId: entity.inviterId,
      invitationCode: entity.invitationCode,
    );
  }

  static List<MemberInvitation> toEntityList(List<MemberInvitationDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<MemberInvitationDto> toDtoList(List<MemberInvitation> entities) {
    return entities.map(toDto).toList();
  }
}
