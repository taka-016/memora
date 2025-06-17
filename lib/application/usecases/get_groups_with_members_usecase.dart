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

  Future<List<GroupWithMembers>> execute() async {
    final groups = await groupRepository.getGroups();
    final groupMembers = await groupMemberRepository.getGroupMembers();
    final allMembers = await memberRepository.getMembers();

    final result = <GroupWithMembers>[];

    for (final group in groups) {
      final groupMemberIds = groupMembers
          .where((gm) => gm.groupId == group.id)
          .map((gm) => gm.memberId)
          .toList();

      final members = allMembers
          .where((member) => groupMemberIds.contains(member.id))
          .toList();

      result.add(GroupWithMembers(group: group, members: members));
    }

    return result;
  }
}