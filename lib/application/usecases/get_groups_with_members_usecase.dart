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
    final allGroups = await _getAllRelatedGroups(member);
    final result = <GroupWithMembers>[];

    for (final group in allGroups) {
      final members = await _getGroupMembers(group.id);
      result.add(GroupWithMembers(group: group, members: members));
    }

    return result;
  }

  Future<List<Group>> _getAllRelatedGroups(Member member) async {
    final adminGroups = await groupRepository.getGroupsByAdministratorId(
      member.id,
    );
    final memberGroups = await _getMemberGroups(member.id);

    return _removeDuplicateGroups([...adminGroups, ...memberGroups]);
  }

  Future<List<Group>> _getMemberGroups(String memberId) async {
    final groupMemberships = await groupMemberRepository
        .getGroupMembersByMemberId(memberId);
    final memberGroups = <Group>[];

    for (final groupMembership in groupMemberships) {
      final group = await groupRepository.getGroupById(groupMembership.groupId);
      if (group != null) {
        memberGroups.add(group);
      }
    }

    return memberGroups;
  }

  List<Group> _removeDuplicateGroups(List<Group> groups) {
    final uniqueGroups = <Group>[];
    final seenGroupIds = <String>{};

    for (final group in groups) {
      if (!seenGroupIds.contains(group.id)) {
        uniqueGroups.add(group);
        seenGroupIds.add(group.id);
      }
    }

    return uniqueGroups;
  }

  Future<List<Member>> _getGroupMembers(String groupId) async {
    final groupMembers = await groupMemberRepository.getGroupMembersByGroupId(
      groupId,
    );
    final members = <Member>[];

    for (final groupMember in groupMembers) {
      final member = await memberRepository.getMemberById(groupMember.memberId);
      if (member != null) {
        members.add(member);
      }
    }

    return members;
  }
}
