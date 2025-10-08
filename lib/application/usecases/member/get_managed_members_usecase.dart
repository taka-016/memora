import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final getManagedMembersUsecaseProvider = Provider<GetManagedMembersUsecase>((
  ref,
) {
  return GetManagedMembersUsecase(ref.watch(memberRepositoryProvider));
});

class GetManagedMembersUsecase {
  final MemberRepository _memberRepository;

  GetManagedMembersUsecase(this._memberRepository);

  Future<List<Member>> execute(Member ownerMember) async {
    return await _memberRepository.getMembersByOwnerId(ownerMember.id);
  }
}
