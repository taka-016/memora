import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/core/app_logger.dart';

final acceptInvitationUseCaseProvider = Provider<AcceptInvitationUseCase>((
  ref,
) {
  return AcceptInvitationUseCase(
    ref.watch(memberInvitationRepositoryProvider),
    ref.watch(memberRepositoryProvider),
  );
});

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
    } catch (e, stack) {
      logger.e(
        'AcceptInvitationUseCase.execute: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
