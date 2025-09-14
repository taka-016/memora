import '../../../domain/entities/member.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/member_repository.dart';

class CreateMemberFromUserUseCase {
  final MemberRepository _memberRepository;

  CreateMemberFromUserUseCase(this._memberRepository);

  Future<bool> execute(User user) async {
    try {
      final newMember = Member(
        id: '',
        displayName: user.loginId,
        accountId: user.id,
        email: user.loginId,
      );

      await _memberRepository.saveMember(newMember);
      return true;
    } catch (e) {
      return false;
    }
  }
}
