import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';

class CreateCalendarEventUsecase {
  CreateCalendarEventUsecase(this._repository);

  final CalendarEventRepository _repository;

  Future<String> execute(CalendarEventDto dto) async {
    try {
      final entity = CalendarEventMapper.toEntity(dto);
      return await _repository.saveCalendarEvent(entity);
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }
}
