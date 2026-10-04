import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';

class DeleteCalendarLabelUsecase {
  DeleteCalendarLabelUsecase(this._repository);

  final CalendarLabelRepository _repository;

  Future<void> execute(String id) async {
    try {
      await _repository.deleteCalendarLabel(id);
    } on ValidationException catch (error, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(error.message),
        stack,
      );
    }
  }
}
