import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createMemberUsecaseProvider = Provider<CreateMemberUsecase>((ref) {
  return CreateMemberUsecase(ref.watch(memberRepositoryProvider));
});

class CreateMemberUsecase {
  final MemberRepository _memberRepository;

  CreateMemberUsecase(this._memberRepository);

  Future<void> execute(MemberDto editedMember, String ownerId) async {
    final editedMemberEntity = MemberMapper.toEntity(editedMember);
    final newMember = editedMemberEntity.copyWith(id: '', ownerId: ownerId);

    await _memberRepository.saveMember(newMember);
  }
}
