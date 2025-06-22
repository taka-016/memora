import '../../domain/entities/member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/member_repository.dart';

class GetOrCreateMemberUseCase {
  final MemberRepository _memberRepository;

  GetOrCreateMemberUseCase(this._memberRepository);

  Future<Member> execute(User user) async {
    // 既存のメンバーをaccountIdで検索
    final existingMember = await _memberRepository.getMemberByAccountId(
      user.id,
    );

    if (existingMember != null) {
      return existingMember;
    }

    // メンバーが見つからない場合、新規作成
    final newMember = Member(
      id: '', // Firestoreで自動生成されるID
      accountId: user.id,
      email: user.email,
    );

    await _memberRepository.saveMember(newMember);
    return newMember;
  }
}
