import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';

class GroupWithMembers {
  final Group group;
  final List<Member> members;

  GroupWithMembers({required this.group, required this.members});
}

class GetGroupsWithMembersUsecase {
  final GroupRepository groupRepository;
  final GroupMemberRepository groupMemberRepository;
  final MemberRepository memberRepository;

  GetGroupsWithMembersUsecase({
    required this.groupRepository,
    required this.groupMemberRepository,
    required this.memberRepository,
  });

  Future<List<GroupWithMembers>> execute(Member member) async {
    final groups = await groupRepository.getGroupsByAdministratorId(member.id);

    final result = <GroupWithMembers>[];

    for (final group in groups) {
      final groupMembers = await groupMemberRepository.getGroupMembersByGroupId(
        group.id,
      );

      final members = <Member>[];
      for (final groupMember in groupMembers) {
        final member = await memberRepository.getMemberById(
          groupMember.memberId,
        );
        if (member != null) {
          members.add(member);
        }
      }

      result.add(GroupWithMembers(group: group, members: members));
    }

    return result;
  }
}
