import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

class MemberInvitationMapper {
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
