import '../../domain/entities/group.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../domain/repositories/member_repository.dart';

class ManagedGroupWithMembers {
  final Group group;
  final List<Member> members;

  ManagedGroupWithMembers({required this.group, required this.members});
}

class GetManagedGroupsWithMembersUsecase {
  final GroupRepository _groupRepository;
  final GroupMemberRepository _groupMemberRepository;
  final MemberRepository _memberRepository;

  GetManagedGroupsWithMembersUsecase(
    this._groupRepository,
    this._groupMemberRepository,
    this._memberRepository,
  );

  Future<List<ManagedGroupWithMembers>> execute(
    Member administratorMember,
  ) async {
    final managedGroups = await _groupRepository.getGroupsByAdministratorId(
      administratorMember.id,
    );

    final result = <ManagedGroupWithMembers>[];

    for (final group in managedGroups) {
      final members = await _getGroupMembers(group.id);
      result.add(ManagedGroupWithMembers(group: group, members: members));
    }

    return result;
  }

  Future<List<Member>> _getGroupMembers(String groupId) async {
    final groupMembers = await _groupMemberRepository.getGroupMembersByGroupId(
      groupId,
    );
    final members = <Member>[];

    for (final groupMember in groupMembers) {
      final member = await _memberRepository.getMemberById(
        groupMember.memberId,
      );
      if (member != null) {
        members.add(member);
      }
    }

    return members;
  }
}
