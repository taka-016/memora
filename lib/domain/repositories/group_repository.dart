import 'package:memora/domain/entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups();
  Future<void> saveGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<Group?> getGroupById(String groupId);
}