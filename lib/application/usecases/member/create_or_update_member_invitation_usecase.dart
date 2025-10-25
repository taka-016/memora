import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createOrUpdateMemberInvitationUsecaseProvider =
    Provider<CreateOrUpdateMemberInvitationUsecase>((ref) {
      return CreateOrUpdateMemberInvitationUsecase(
        ref.watch(memberInvitationRepositoryProvider),
        ref.watch(memberInvitationQueryServiceProvider),
      );
    });

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

    final invitationCode = const Uuid().v4().replaceAll('-', '');

    if (existingInvitation != null) {
      // 既存招待の更新
      final updatedInvitation = existingInvitation.copyWith(
        invitationCode: invitationCode,
        inviterId: inviterId,
      );
      await _memberInvitationRepository.updateMemberInvitation(
        updatedInvitation,
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
