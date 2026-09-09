import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';

class UpdateMemberUsecase {
  final MemberRepository _memberRepository;

  UpdateMemberUsecase(this._memberRepository);

  Future<void> execute(MemberDto updatedMember) async {
    final entity = MemberMapper.toEntity(updatedMember);
    await _memberRepository.updateMember(entity);
  }
}
