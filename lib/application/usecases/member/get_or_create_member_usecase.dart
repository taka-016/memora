import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/core/app_logger.dart';

class GetOrCreateMemberUseCase {
  final MemberRepository _memberRepository;

  GetOrCreateMemberUseCase(this._memberRepository);

  Future<bool> execute(User user) async {
    try {
      final existingMember = await _memberRepository.getMemberByAccountId(
        user.id,
      );

      if (existingMember != null) {
        return true;
      }

      final newMember = Member(
        id: '', // Firestoreで自動生成されるID
        displayName: user.loginId,
        accountId: user.id,
        email: user.loginId,
      );

      await _memberRepository.saveMember(newMember);
      return true;
    } catch (e, stack) {
      logger.e(
        'GetOrCreateMemberUseCase.execute: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
