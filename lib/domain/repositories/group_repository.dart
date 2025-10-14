import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups({List<OrderBy>? orderBy});
  Future<String> saveGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<void> deleteGroupMembersByMemberId(String memberId);
  Future<Group?> getGroupById(String groupId, {List<OrderBy>? orderBy});
  Future<List<Group>> getGroupsByOwnerId(
    String ownerId, {
    List<OrderBy>? orderBy,
  });
}
