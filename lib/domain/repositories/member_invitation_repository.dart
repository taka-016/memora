import 'package:memora/domain/entities/member_invitation.dart';

abstract class MemberInvitationRepository {
  Future<void> saveMemberInvitation(MemberInvitation memberInvitation);
  Future<void> updateMemberInvitation(MemberInvitation memberInvitation);
  Future<void> deleteMemberInvitation(String id);
}
