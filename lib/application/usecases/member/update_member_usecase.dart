import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateMemberUsecaseProvider = Provider<UpdateMemberUsecase>((ref) {
  return UpdateMemberUsecase(ref.watch(memberRepositoryProvider));
});

class UpdateMemberUsecase {
  final MemberRepository _memberRepository;

  UpdateMemberUsecase(this._memberRepository);

  Future<void> execute(MemberDto updatedMember) async {
    await _memberRepository.updateMember(MemberMapper.toEntity(updatedMember));
  }
}
