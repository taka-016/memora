import '../../../domain/repositories/member_invitation_repository.dart';
import '../../../domain/repositories/member_repository.dart';

class AcceptInvitationUseCase {
  final MemberInvitationRepository _memberInvitationRepository;
  final MemberRepository _memberRepository;

  AcceptInvitationUseCase(
    this._memberInvitationRepository,
    this._memberRepository,
  );

  Future<bool> execute(String invitationCode, String userId) async {
    try {
      final memberInvitation = await _memberInvitationRepository
          .getByInvitationCode(invitationCode);

      if (memberInvitation == null) {
        return false;
      }

      final member = await _memberRepository.getMemberById(
        memberInvitation.inviteeId,
      );

      if (member == null) {
        return false;
      }

      if (member.accountId != null) {
        return false;
      }

      final updatedMember = member.copyWith(accountId: userId);
      await _memberRepository.updateMember(updatedMember);

      return true;
    } catch (e) {
      return false;
    }
  }
}
