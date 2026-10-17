import 'package:memora/domain/repositories/member/member_repository.dart';

class DeleteMemberUsecase {
  final MemberRepository _memberRepository;

  DeleteMemberUsecase(this._memberRepository);

  Future<void> execute(String memberId) async {
    await _memberRepository.deleteMember(memberId);
  }
}
