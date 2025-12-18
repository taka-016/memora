import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/core/app_logger.dart';

final acceptInvitationUseCaseProvider = Provider<AcceptInvitationUseCase>((
  ref,
) {
  return AcceptInvitationUseCase(
    ref.watch(memberInvitationQueryServiceProvider),
    ref.watch(memberRepositoryProvider),
    ref.watch(memberQueryServiceProvider),
  );
});

class AcceptInvitationUseCase {
  final MemberInvitationQueryService _memberInvitationQueryService;
  final MemberRepository _memberRepository;
  final MemberQueryService _memberQueryService;

  AcceptInvitationUseCase(
    this._memberInvitationQueryService,
    this._memberRepository,
    this._memberQueryService,
  );

  Future<bool> execute(String invitationCode, String userId) async {
    try {
      final memberInvitation = await _memberInvitationQueryService
          .getByInvitationCode(invitationCode);

      if (memberInvitation == null) {
        return false;
      }

      final member = await _memberQueryService.getMemberById(
        memberInvitation.inviteeId,
      );

      if (member == null) {
        return false;
      }

      final updatedMember = MemberMapper.toEntity(
        member.copyWith(accountId: userId),
      );
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
