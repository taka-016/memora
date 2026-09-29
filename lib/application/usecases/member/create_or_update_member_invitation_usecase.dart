import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';

class CreateOrUpdateMemberInvitationUsecase {
  final MemberInvitationRepository _memberInvitationRepository;
  final MemberInvitationQueryService _memberInvitationQueryService;

  CreateOrUpdateMemberInvitationUsecase(
    this._memberInvitationRepository,
    this._memberInvitationQueryService,
  );

  Future<String> execute({
    required String inviteeId,
    required String inviterId,
  }) async {
    // 既存の招待があるか確認
    final existingInvitation = await _memberInvitationQueryService
        .getByInviteeId(inviteeId);

    final invitationCode = const Uuid().v7().replaceAll('-', '');

    if (existingInvitation != null) {
      // 既存招待の更新
      final updatedInvitation = existingInvitation.copyWith(
        invitationCode: invitationCode,
        inviterId: inviterId,
      );
      await _memberInvitationRepository.updateMemberInvitation(
        MemberInvitationMapper.toEntity(updatedInvitation),
      );
    } else {
      // 新規招待の作成
      final newInvitation = MemberInvitation(
        id: '',
        inviteeId: inviteeId,
        inviterId: inviterId,
        invitationCode: invitationCode,
      );
      await _memberInvitationRepository.saveMemberInvitation(newInvitation);
    }

    return invitationCode;
  }
}
