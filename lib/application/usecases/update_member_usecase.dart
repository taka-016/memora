import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';

class UpdateMemberUsecase {
  final MemberRepository _memberRepository;

  UpdateMemberUsecase(this._memberRepository);

  Future<void> execute(Member updatedMember) async {
    await _memberRepository.updateMember(updatedMember);
  }
}
