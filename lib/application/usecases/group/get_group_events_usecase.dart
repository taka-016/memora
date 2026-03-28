import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getGroupEventsUsecaseProvider = Provider<GetGroupEventsUsecase>((ref) {
  return GetGroupEventsUsecase(ref.watch(groupEventQueryServiceProvider));
});

class GetGroupEventsUsecase {
  final GroupEventQueryService _groupEventQueryService;

  GetGroupEventsUsecase(this._groupEventQueryService);

  Future<List<GroupEventDto>> execute(String groupId) async {
    try {
      return await _groupEventQueryService.getGroupEventsByGroupId(
        groupId,
        orderBy: const [OrderBy('year', descending: false)],
      );
    } catch (e, stack) {
      logger.e(
        'GetGroupEventsUsecase.execute: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
