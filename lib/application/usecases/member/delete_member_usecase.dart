import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_event_repository.dart';

class DeleteMemberUsecase {
  final MemberRepository _memberRepository;
  final GroupRepository _groupRepository;
  final MemberEventRepository _memberEventRepository;

  DeleteMemberUsecase(
    this._memberRepository,
    this._groupRepository,
    this._memberEventRepository,
  );

  Future<void> execute(String memberId) async {
    await _groupRepository.deleteGroupMembersByMemberId(memberId);
    await _memberEventRepository.deleteMemberEventsByMemberId(memberId);
    await _memberRepository.deleteMember(memberId);
  }
}
