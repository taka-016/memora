import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateMemberUsecaseProvider = Provider<UpdateMemberUsecase>((ref) {
  return UpdateMemberUsecase(ref.watch(memberRepositoryProvider));
});

class UpdateMemberUsecase {
  final MemberRepository _memberRepository;

  UpdateMemberUsecase(this._memberRepository);

  Future<void> execute(Member updatedMember) async {
    await _memberRepository.updateMember(updatedMember);
  }
}
