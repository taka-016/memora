import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final getMemberByIdUsecaseProvider = Provider<GetMemberByIdUseCase>((ref) {
  return GetMemberByIdUseCase(ref.watch(memberRepositoryProvider));
});

class GetMemberByIdUseCase {
  final MemberRepository _memberRepository;

  GetMemberByIdUseCase(this._memberRepository);

  Future<Member?> execute(String id) async {
    return await _memberRepository.getMemberById(id);
  }
}
