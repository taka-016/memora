import 'package:memora/domain/entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups();
  Future<String> saveGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<Group?> getGroupById(String groupId);
  Future<List<Group>> getGroupsByAdministratorId(String administratorId);
}
