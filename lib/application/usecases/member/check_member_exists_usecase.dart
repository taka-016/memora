import '../../../domain/entities/user.dart';
import '../../../domain/repositories/member_repository.dart';

class CheckMemberExistsUseCase {
  final MemberRepository _memberRepository;

  CheckMemberExistsUseCase(this._memberRepository);

  Future<bool> execute(User user) async {
    try {
      final existingMember = await _memberRepository.getMemberByAccountId(
        user.id,
      );
      return existingMember != null;
    } catch (e) {
      return false;
    }
  }
}
