import '../../domain/entities/group_member.dart';
import '../../domain/repositories/group_member_repository.dart';

class GetGroupMembersByGroupIdUsecase {
  final GroupMemberRepository _groupMemberRepository;

  GetGroupMembersByGroupIdUsecase(this._groupMemberRepository);

  Future<List<GroupMember>> execute(String groupId) async {
    return await _groupMemberRepository.getGroupMembersByGroupId(groupId);
  }
}
