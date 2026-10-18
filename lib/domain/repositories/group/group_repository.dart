import 'package:memora/domain/entities/group/group.dart';

abstract class GroupRepository {
  Future<String> saveGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId, {int? expectedVersion});
  Future<void> deleteGroupMembersByMemberId(String memberId);
}
