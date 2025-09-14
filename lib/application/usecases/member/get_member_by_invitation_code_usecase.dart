import '../../../domain/entities/member.dart';
import '../../../domain/repositories/member_invitation_repository.dart';
import '../../../domain/repositories/member_repository.dart';

class GetMemberByInvitationCodeUseCase {
  final MemberInvitationRepository _memberInvitationRepository;
  final MemberRepository _memberRepository;

  GetMemberByInvitationCodeUseCase(
    this._memberInvitationRepository,
    this._memberRepository,
  );

  Future<Member?> execute(String invitationCode) async {
    try {
      final memberInvitation = await _memberInvitationRepository
          .getByInvitationCode(invitationCode);

      if (memberInvitation == null) {
        return null;
      }

      final member = await _memberRepository.getMemberById(
        memberInvitation.inviteeId,
      );

      return member;
    } catch (e) {
      return null;
    }
  }
}
