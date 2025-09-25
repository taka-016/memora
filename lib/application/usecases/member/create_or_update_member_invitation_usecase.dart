import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';

class CreateOrUpdateMemberInvitationUsecase {
  final MemberInvitationRepository _memberInvitationRepository;

  CreateOrUpdateMemberInvitationUsecase(this._memberInvitationRepository);

  Future<String> execute({
    required String inviteeId,
    required String inviterId,
  }) async {
    // 既存の招待があるか確認
    final existingInvitation = await _memberInvitationRepository.getByInviteeId(
      inviteeId,
    );

    final invitationCode = const Uuid().v4().replaceAll('-', '');

    if (existingInvitation != null) {
      // 既存招待の更新
      final updatedInvitation = existingInvitation.copyWith(
        invitationCode: invitationCode,
        inviterId: inviterId,
      );
      await _memberInvitationRepository.save(updatedInvitation);
    } else {
      // 新規招待の作成
      final newInvitation = MemberInvitation(
        id: '',
        inviteeId: inviteeId,
        inviterId: inviterId,
        invitationCode: invitationCode,
      );
      await _memberInvitationRepository.save(newInvitation);
    }

    return invitationCode;
  }
}
