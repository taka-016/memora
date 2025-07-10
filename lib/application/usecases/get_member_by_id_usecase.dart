import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';

class GetMemberByIdUseCase {
  final MemberRepository _memberRepository;

  GetMemberByIdUseCase(this._memberRepository);

  Future<Member?> execute(String id) async {
    return await _memberRepository.getMemberById(id);
  }
}
