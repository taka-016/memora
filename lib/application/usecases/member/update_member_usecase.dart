import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';

class UpdateMemberUsecase {
  final MemberRepository _memberRepository;

  UpdateMemberUsecase(this._memberRepository);

  Future<void> execute(Member updatedMember) async {
    await _memberRepository.updateMember(updatedMember);
  }
}
