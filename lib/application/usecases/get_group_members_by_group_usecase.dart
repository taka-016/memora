import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/repositories/group_member_repository.dart';

class GetGroupMembersByGroupUsecase {
  final GroupMemberRepository _groupMemberRepository;

  GetGroupMembersByGroupUsecase(this._groupMemberRepository);

  Future<List<GroupMember>> execute(Group group) async {
    return await _groupMemberRepository.getGroupMembersByGroupId(group.id);
  }
}
