import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';

class CreateMemberUsecase {
  final MemberRepository _memberRepository;

  CreateMemberUsecase(this._memberRepository);

  Future<void> execute(Member member) async {
    await _memberRepository.saveMember(member);
  }
}
