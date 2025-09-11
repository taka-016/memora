import '../../../domain/entities/member.dart';
import '../../../domain/repositories/member_repository.dart';

class GetManagedMembersUsecase {
  final MemberRepository _memberRepository;

  GetManagedMembersUsecase(this._memberRepository);

  Future<List<Member>> execute(Member ownerMember) async {
    return await _memberRepository.getMembersByOwnerId(ownerMember.id);
  }
}
