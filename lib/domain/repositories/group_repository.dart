import 'package:memora/domain/entities/group.dart';

abstract class GroupRepository {
  Future<String> saveGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<void> deleteGroupMembersByMemberId(String memberId);
  Future<Group?> getGroupById(String groupId);
}
