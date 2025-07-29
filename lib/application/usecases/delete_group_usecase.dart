import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/group_member_repository.dart';

class DeleteGroupUsecase {
  final GroupRepository _groupRepository;
  final GroupMemberRepository _groupMemberRepository;

  DeleteGroupUsecase(this._groupRepository, this._groupMemberRepository);

  Future<void> execute(String groupId) async {
    await _groupMemberRepository.deleteGroupMembersByGroupId(groupId);
    await _groupRepository.deleteGroup(groupId);
  }
}
