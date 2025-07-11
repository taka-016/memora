import '../../domain/entities/member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/member_repository.dart';

class GetOrCreateMemberUseCase {
  final MemberRepository _memberRepository;

  GetOrCreateMemberUseCase(this._memberRepository);

  Future<bool> execute(User user) async {
    try {
      // 既存のメンバーをaccountIdで検索
      final existingMember = await _memberRepository.getMemberByAccountId(
        user.id,
      );

      if (existingMember != null) {
        return true;
      }

      // メンバーが見つからない場合、新規作成
      final newMember = Member(
        id: '', // Firestoreで自動生成されるID
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
