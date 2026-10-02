import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';

class DeleteCalendarEventUsecase {
  DeleteCalendarEventUsecase(this._repository);

  final CalendarEventRepository _repository;

  Future<void> execute(String id) async {
    await _repository.deleteCalendarEvent(id);
  }
}
