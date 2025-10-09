import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final checkMemberExistsUseCaseProvider = Provider<CheckMemberExistsUseCase>((
  ref,
) {
  return CheckMemberExistsUseCase(ref.watch(memberRepositoryProvider));
});

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
