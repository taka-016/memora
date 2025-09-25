import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';

class CheckMemberExistsUseCase {
  final MemberRepository _memberRepository;

  CheckMemberExistsUseCase(this._memberRepository);

  Future<bool> execute(User user) async {
    final existingMember = await _memberRepository.getMemberByAccountId(
      user.id,
    );
    return existingMember != null;
  }
}
