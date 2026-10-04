import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';

class DeleteCalendarLabelUsecase {
  DeleteCalendarLabelUsecase(this._repository);

  final CalendarLabelRepository _repository;

  Future<void> execute(String id) async {
    await _repository.deleteCalendarLabel(id);
  }
}
