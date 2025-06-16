import 'package:memora/domain/entities/group_event.dart';

abstract class GroupEventRepository {
  Future<List<GroupEvent>> getGroupEvents();
  Future<void> saveGroupEvent(GroupEvent groupEvent);
  Future<void> deleteGroupEvent(String groupEventId);
  Future<List<GroupEvent>> getGroupEventsByGroupId(String groupId);
}