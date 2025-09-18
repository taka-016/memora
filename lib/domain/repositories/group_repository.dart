import 'package:memora/domain/entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups();
  Future<String> saveGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<void> deleteGroupMembersByMemberId(String memberId);
  Future<Group?> getGroupById(String groupId);
  Future<List<Group>> getGroupsByOwnerId(String ownerId);
  Future<List<Group>> getGroupsWhereUserIsAdmin(String memberId);
  Future<List<Group>> getGroupsWhereUserIsMember(String memberId);
}
