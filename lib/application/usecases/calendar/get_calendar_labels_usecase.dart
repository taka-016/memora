import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';

class GetCalendarLabelsUsecase {
  GetCalendarLabelsUsecase(this._queryService);

  final CalendarLabelQueryService _queryService;

  Future<List<CalendarLabelDto>> execute(String groupId) async {
    return await _queryService.getCalendarLabelsByGroupId(groupId);
  }
}
