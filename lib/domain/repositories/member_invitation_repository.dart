import 'package:memora/domain/entities/member_invitation.dart';

abstract class MemberInvitationRepository {
  Future<MemberInvitation?> getByInviteeId(String inviteeId);
  Future<MemberInvitation?> getByInvitationCode(String invitationCode);
  Future<void> save(MemberInvitation memberInvitation);
  Future<void> delete(String id);
}
