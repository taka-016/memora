import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

abstract class MemberInvitationRepository {
  Future<void> acceptInvitation(
    Member member,
    List<MemberInvitation> invitations,
  );

  Future<void> saveMemberInvitation(MemberInvitation memberInvitation);
  Future<void> updateMemberInvitation(MemberInvitation memberInvitation);
  Future<void> deleteMemberInvitation(String id, {int? expectedVersion});
}
