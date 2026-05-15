import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/core/app_logger.dart';

final acceptInvitationUseCaseProvider = Provider<AcceptInvitationUseCase>((
  ref,
) {
  return AcceptInvitationUseCase(
    ref.watch(memberInvitationQueryServiceProvider),
    ref.watch(memberInvitationRepositoryProvider),
    ref.watch(memberRepositoryProvider),
    ref.watch(memberQueryServiceProvider),
    ref.watch(appClockProvider),
  );
});

class AcceptInvitationUseCase {
  static const invitationValidDuration = Duration(hours: 24);

  final MemberInvitationQueryService _memberInvitationQueryService;
  final MemberInvitationRepository _memberInvitationRepository;
  final MemberRepository _memberRepository;
  final MemberQueryService _memberQueryService;
  final AppClock _clock;

  AcceptInvitationUseCase(
    this._memberInvitationQueryService,
    this._memberInvitationRepository,
    this._memberRepository,
    this._memberQueryService,
    this._clock,
  );

  Future<bool> execute(
    String invitationCode,
    String userId, {
    DateTime? now,
  }) async {
    try {
      final memberInvitation = await _memberInvitationQueryService
          .getByInvitationCode(invitationCode);

      if (memberInvitation == null) {
        return false;
      }

      if (_isExpired(_issuedAt(memberInvitation), now ?? _clock.now())) {
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
      await _memberInvitationRepository.deleteMemberInvitation(
        memberInvitation.id,
      );

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

  DateTime? _issuedAt(MemberInvitationDto memberInvitation) {
    return memberInvitation.updatedAt ?? memberInvitation.createdAt;
  }

  bool _isExpired(DateTime? issuedAt, DateTime now) {
    if (issuedAt == null) {
      return false;
    }

    return now.difference(issuedAt) > invitationValidDuration;
  }
}
