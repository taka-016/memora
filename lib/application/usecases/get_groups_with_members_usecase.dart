import 'package:memora/domain/entities/group_with_members.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_repository.dart';

class GetGroupsWithMembersUsecase {
  final GroupRepository groupRepository;

  GetGroupsWithMembersUsecase({required this.groupRepository});

  Future<List<GroupWithMembers>> execute(Member member) async {
    return await groupRepository.getGroupsWithMembersByMemberId(member.id);
  }
}
