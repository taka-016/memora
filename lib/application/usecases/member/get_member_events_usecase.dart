import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

class GetMemberEventsUsecase {
  final MemberEventQueryService _memberEventQueryService;

  GetMemberEventsUsecase(this._memberEventQueryService);

  Future<List<MemberEventDto>> execute(
    List<String> memberIds, {
    required String groupId,
  }) async {
    return await _memberEventQueryService.getMemberEventsByMemberIds(
      memberIds,
      groupId: groupId,
      orderBy: const [OrderBy('year', descending: false)],
    );
  }
}
