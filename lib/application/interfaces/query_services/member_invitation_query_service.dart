import 'package:memora/domain/entities/member_invitation.dart';

abstract class MemberInvitationQueryService {
  Future<MemberInvitation?> getByInviteeId(String inviteeId);

  Future<MemberInvitation?> getByInvitationCode(String invitationCode);
}
