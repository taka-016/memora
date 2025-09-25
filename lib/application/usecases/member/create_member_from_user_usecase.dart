import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/core/app_logger.dart';

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
    } catch (e, stack) {
      logger.e(
        'CreateMemberFromUserUseCase.execute: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
