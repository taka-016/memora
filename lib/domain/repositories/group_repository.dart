import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_with_members.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups();
  Future<String> saveGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<Group?> getGroupById(String groupId);
  Future<List<Group>> getGroupsByAdministratorId(String administratorId);
  Future<List<Group>> getGroupsWhereUserIsAdmin(String memberId);
  Future<List<Group>> getGroupsWhereUserIsMember(String memberId);
  Future<List<GroupWithMembers>> addMembersToGroups(List<Group> groups);
  Future<List<GroupWithMembers>> getGroupsWithMembersByMemberId(
    String memberId,
  );
  Future<List<GroupWithMembers>> getManagedGroupsWithMembersByAdministratorId(
    String administratorId,
  );
}
