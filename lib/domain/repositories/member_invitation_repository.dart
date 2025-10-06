import 'package:memora/domain/entities/member_invitation.dart';

abstract class MemberInvitationRepository {
  Future<void> saveMemberInvitation(MemberInvitation memberInvitation);
  Future<void> deleteMemberInvitation(String id);
  Future<MemberInvitation?> getByInviteeId(String inviteeId);
  Future<MemberInvitation?> getByInvitationCode(String invitationCode);
}
