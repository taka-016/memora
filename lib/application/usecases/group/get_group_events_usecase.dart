import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

class GetGroupEventsUsecase {
  final GroupEventQueryService _groupEventQueryService;

  GetGroupEventsUsecase(this._groupEventQueryService);

  Future<List<GroupEventDto>> execute(String groupId) async {
    return await _groupEventQueryService.getGroupEventsByGroupId(
      groupId,
      orderBy: const [OrderBy('year', descending: false)],
    );
  }
}
