import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/order_by.dart';

abstract class MemberEventQueryService {
  Future<List<MemberEventDto>> getMemberEventsByMemberIds(
    List<String> memberIds, {
    List<OrderBy>? orderBy,
  });
}
