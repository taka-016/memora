import 'package:memora/domain/entities/group_member.dart';

abstract class GroupMemberRepository {
  Future<List<GroupMember>> getGroupMembers();
  Future<void> saveGroupMember(GroupMember groupMember);
  Future<void> deleteGroupMember(String groupMemberId);
  Future<List<GroupMember>> getGroupMembersByGroupId(String groupId);
  Future<List<GroupMember>> getGroupMembersByMemberId(String memberId);
}
