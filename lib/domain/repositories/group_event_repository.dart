import 'package:memora/domain/entities/group_event.dart';

abstract class GroupEventRepository {
  Future<void> saveGroupEvent(GroupEvent groupEvent);
  Future<void> deleteGroupEvent(String groupEventId);
  Future<void> deleteGroupEventsByGroupId(String groupId);
}
