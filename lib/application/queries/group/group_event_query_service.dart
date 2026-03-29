import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/order_by.dart';

abstract class GroupEventQueryService {
  Future<List<GroupEventDto>> getGroupEventsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  });
}
