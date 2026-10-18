import 'package:memora/application/dtos/member/member_invitation_dto.dart';

abstract class MemberInvitationQueryService {
  Future<List<MemberInvitationDto>> getAllByInviteeId(String inviteeId);

  Future<MemberInvitationDto?> getByInviteeId(String inviteeId);

  Future<MemberInvitationDto?> getByInvitationCode(String invitationCode);
}
