import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getMemberEventsUsecaseProvider = Provider<GetMemberEventsUsecase>((ref) {
  return GetMemberEventsUsecase(ref.watch(memberEventQueryServiceProvider));
});

class GetMemberEventsUsecase {
  final MemberEventQueryService _memberEventQueryService;

  GetMemberEventsUsecase(this._memberEventQueryService);

  Future<List<MemberEventDto>> execute(List<String> memberIds) async {
    try {
      return await _memberEventQueryService.getMemberEventsByMemberIds(
        memberIds,
        orderBy: const [OrderBy('year', descending: false)],
      );
    } catch (e, stack) {
      logger.e(
        'GetMemberEventsUsecase.execute: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
